-- 006_security_rls_hardening.sql
-- Security hardening based on SECURITY_RLS_REVIEW_AR.md.
-- Run on staging first, then verify the RPC and RLS test cases before production.

-- ============================================================
-- 1. Harden helper functions and profile creation
-- ============================================================

ALTER TABLE IF EXISTS public.conversation_participants
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS ban_reason TEXT,
  ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS banned_by UUID REFERENCES public.profiles(id);

CREATE OR REPLACE FUNCTION public.is_instructor()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'instructor'
      AND is_active = TRUE
      AND is_banned = FALSE
  );
$$;

-- This project currently uses the single-instructor model. Keep the existing
-- behavior, but make the check explicit and active-user only.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT public.is_instructor();
$$;

CREATE OR REPLACE FUNCTION public.is_enrolled(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.enrollments
    WHERE user_id = auth.uid()
      AND course_id = p_course_id
      AND status IN ('active', 'completed')
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_course(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.courses c
    JOIN public.profiles p ON p.id = auth.uid()
    WHERE c.id = p_course_id
      AND p.role = 'instructor'
      AND p.is_active = TRUE
      AND p.is_banned = FALSE
      AND (c.instructor_id = auth.uid() OR public.is_admin())
  );
$$;

CREATE OR REPLACE FUNCTION public.current_profile_sensitive_state()
RETURNS TABLE (
  role TEXT,
  is_active BOOLEAN,
  is_banned BOOLEAN,
  banned_until TIMESTAMPTZ,
  ban_reason TEXT,
  is_verified_instructor BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    p.role,
    p.is_active,
    p.is_banned,
    p.banned_until,
    p.ban_reason,
    p.is_verified_instructor
  FROM public.profiles p
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    'student',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$;

-- ============================================================
-- 2. Lock profile self-updates to non-sensitive fields
-- ============================================================

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update safe profile fields" ON public.profiles;

CREATE POLICY "Users can update safe profile fields"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role IS NOT DISTINCT FROM (
    SELECT s.role FROM public.current_profile_sensitive_state() s
  )
  AND is_active IS NOT DISTINCT FROM (
    SELECT s.is_active FROM public.current_profile_sensitive_state() s
  )
  AND is_banned IS NOT DISTINCT FROM (
    SELECT s.is_banned FROM public.current_profile_sensitive_state() s
  )
  AND banned_until IS NOT DISTINCT FROM (
    SELECT s.banned_until FROM public.current_profile_sensitive_state() s
  )
  AND ban_reason IS NOT DISTINCT FROM (
    SELECT s.ban_reason FROM public.current_profile_sensitive_state() s
  )
  AND is_verified_instructor IS NOT DISTINCT FROM (
    SELECT s.is_verified_instructor FROM public.current_profile_sensitive_state() s
  )
);

-- ============================================================
-- 3. Enable missing RLS and add policies for sensitive tables
-- ============================================================

ALTER TABLE IF EXISTS public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.instructor_earnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can manage members" ON public.conversation_participants;
DROP POLICY IF EXISTS "Course managers can manage conversation members" ON public.conversation_participants;
CREATE POLICY "Course managers can manage conversation members"
ON public.conversation_participants
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conversation_id
      AND c.course_id IS NOT NULL
      AND public.can_manage_course(c.course_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conversation_id
      AND c.course_id IS NOT NULL
      AND public.can_manage_course(c.course_id)
  )
);

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can mark own notifications read" ON public.notifications;
CREATE POLICY "Users can mark own notifications read"
ON public.notifications
FOR UPDATE
USING (user_id = auth.uid() OR public.is_admin())
WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Instructors can view own earnings" ON public.instructor_earnings;
CREATE POLICY "Instructors can view own earnings"
ON public.instructor_earnings
FOR SELECT
USING (instructor_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage earnings" ON public.instructor_earnings;
CREATE POLICY "Admins can manage earnings"
ON public.instructor_earnings
FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ============================================================
-- 4. Harden enrollment, payment, refund, and chat RPCs
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_coupon RECORD;
  v_total_subtotal DECIMAL := 0;
  v_coupon_discount DECIMAL := 0;
  v_user_usage_count INTEGER := 0;
BEGIN
  SELECT NULL::UUID AS id, NULL::VARCHAR AS code INTO v_coupon;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create enrollment for another user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cart_items WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  SELECT COALESCE(SUM(
    CASE
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0)
  INTO v_total_subtotal
  FROM public.cart_items ci
  JOIN public.courses c ON c.id = ci.course_id
  WHERE ci.user_id = v_user_id;

  IF p_coupon_id IS NOT NULL OR p_coupon_code IS NOT NULL THEN
    SELECT *
    INTO v_coupon
    FROM public.coupons
    WHERE (id = p_coupon_id OR code = UPPER(p_coupon_code))
      AND is_active = TRUE
      AND is_suspended = FALSE
      AND start_date <= NOW()
      AND (end_date IS NULL OR end_date >= NOW())
      AND (usage_limit IS NULL OR usage_count < usage_limit)
      AND min_order_amount <= v_total_subtotal
    LIMIT 1;

    IF v_coupon.id IS NULL THEN
      RAISE EXCEPTION 'Invalid coupon';
    END IF;

    SELECT COUNT(*)
    INTO v_user_usage_count
    FROM public.coupon_usages
    WHERE coupon_id = v_coupon.id
      AND user_id = v_user_id;

    IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
      RAISE EXCEPTION 'Coupon usage limit exceeded';
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
      v_coupon_discount := v_total_subtotal * (v_coupon.discount_value / 100);
      IF v_coupon.max_discount_amount IS NOT NULL THEN
        v_coupon_discount := LEAST(v_coupon_discount, v_coupon.max_discount_amount);
      END IF;
    ELSE
      v_coupon_discount := LEAST(v_coupon.discount_value, v_total_subtotal);
    END IF;
  END IF;

  INSERT INTO public.parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    v_user_id,
    GREATEST(v_total_subtotal - v_coupon_discount, 0),
    v_total_subtotal,
    v_coupon_discount,
    v_coupon.id,
    v_coupon.code,
    v_coupon_discount,
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.instructor_id,
      CASE
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END AS final_price
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    INSERT INTO public.enrollments (
      user_id, course_id, instructor_id, parent_enrollment_id,
      price, discount, status, enrolled_at
    )
    VALUES (
      v_user_id,
      v_course.course_id,
      v_course.instructor_id,
      v_parent_enrollment_id,
      v_course.final_price,
      CASE
        WHEN v_total_subtotal > 0 THEN ROUND(v_coupon_discount * (v_course.final_price / v_total_subtotal), 2)
        ELSE 0
      END,
      CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  IF v_coupon.id IS NOT NULL THEN
    INSERT INTO public.coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (v_coupon.id, v_user_id, v_parent_enrollment_id, v_coupon_discount);

    UPDATE public.coupons
    SET usage_count = usage_count + 1
    WHERE id = v_coupon.id;
  END IF;

  DELETE FROM public.cart_items WHERE user_id = v_user_id;

  RETURN v_parent_enrollment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.confirm_enrollment_payment(
  p_parent_enrollment_id UUID,
  p_transaction_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.parent_enrollments
  SET payment_status = 'paid',
      payment_transaction_id = p_transaction_id,
      paid_at = NOW(),
      updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status <> 'paid';

  UPDATE public.enrollments
  SET status = 'active',
      updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id
    AND status = 'pending';

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_refund(
  p_enrollment_id UUID,
  p_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course_id UUID;
BEGIN
  SELECT course_id
  INTO v_course_id
  FROM public.enrollments
  WHERE id = p_enrollment_id;

  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'Enrollment not found';
  END IF;

  IF NOT public.can_manage_course(v_course_id) THEN
    RAISE EXCEPTION 'Not authorized to refund this enrollment';
  END IF;

  UPDATE public.enrollments
  SET status = 'refunded',
      refunded_at = NOW(),
      refund_reason = p_reason,
      updated_at = NOW()
  WHERE id = p_enrollment_id;

  UPDATE public.parent_enrollments pe
  SET payment_status = 'refunded',
      updated_at = NOW()
  WHERE pe.id = (
    SELECT e.parent_enrollment_id
    FROM public.enrollments e
    WHERE e.id = p_enrollment_id
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.enrollments e2
    WHERE e2.parent_enrollment_id = pe.id
      AND e2.status <> 'refunded'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_course_conversation(p_course_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_conversation_id UUID;
  v_instructor_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT (public.is_enrolled(p_course_id) OR public.can_manage_course(p_course_id)) THEN
    RAISE EXCEPTION 'Not authorized to join this course conversation';
  END IF;

  SELECT id
  INTO v_conversation_id
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    SELECT instructor_id
    INTO v_instructor_id
    FROM public.courses
    WHERE id = p_course_id;

    INSERT INTO public.conversations (type, course_id, title, created_by)
    SELECT 'multi', p_course_id, COALESCE(c.title_ar, c.title_en, 'Course Forum'), COALESCE(v_instructor_id, v_user_id)
    FROM public.courses c
    WHERE c.id = p_course_id
    RETURNING id INTO v_conversation_id;

    IF v_instructor_id IS NOT NULL THEN
      INSERT INTO public.conversation_participants (conversation_id, user_id, role)
      VALUES (v_conversation_id, v_instructor_id, 'admin')
      ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;
  END IF;

  INSERT INTO public.conversation_participants (conversation_id, user_id, role)
  VALUES (v_conversation_id, v_user_id, CASE WHEN public.can_manage_course(p_course_id) THEN 'admin' ELSE 'member' END)
  ON CONFLICT (conversation_id, user_id) DO NOTHING;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_course_conversation(p_course_id UUID, p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot create conversation for another user';
  END IF;

  RETURN public.get_or_create_course_conversation(p_course_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_single_conversation(p_user1_id UUID, p_user2_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_conversation_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user1_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create conversation for another user';
  END IF;

  IF p_user1_id = p_user2_id THEN
    RAISE EXCEPTION 'Cannot create self conversation';
  END IF;

  SELECT c.id
  INTO v_conversation_id
  FROM public.conversations c
  JOIN public.conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = p_user1_id
  JOIN public.conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = p_user2_id
  WHERE c.type = 'single'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    INSERT INTO public.conversations (type, created_by)
    VALUES ('single', p_user1_id)
    RETURNING id INTO v_conversation_id;

    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    VALUES
      (v_conversation_id, p_user1_id, 'member'),
      (v_conversation_id, p_user2_id, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
  END IF;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_type TEXT DEFAULT NULL)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type VARCHAR(10),
  conversation_title TEXT,
  course_id UUID,
  created_at TIMESTAMPTZ,
  last_message_id UUID,
  last_message_text TEXT,
  last_message_user_id UUID,
  last_message_user_name TEXT,
  last_message_created_at TIMESTAMPTZ,
  participants_count BIGINT,
  other_user_name TEXT,
  other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS conversation_id,
    c.type AS conversation_type,
    c.title AS conversation_title,
    c.course_id,
    c.created_at,
    lm.id AS last_message_id,
    lm.message_text AS last_message_text,
    lm.user_id AS last_message_user_id,
    p_sender.name AS last_message_user_name,
    lm.created_at AS last_message_created_at,
    (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
    CASE WHEN c.type = 'single' THEN (
      SELECT p_other.name
      FROM public.conversation_participants cp_other
      JOIN public.profiles p_other ON p_other.id = cp_other.user_id
      WHERE cp_other.conversation_id = c.id
        AND cp_other.user_id <> v_user_id
      LIMIT 1
    ) ELSE NULL END AS other_user_name,
    CASE WHEN c.type = 'single' THEN (
      SELECT p_other.avatar_url
      FROM public.conversation_participants cp_other
      JOIN public.profiles p_other ON p_other.id = cp_other.user_id
      WHERE cp_other.conversation_id = c.id
        AND cp_other.user_id <> v_user_id
      LIMIT 1
    ) ELSE NULL END AS other_user_avatar
  FROM public.conversations c
  JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = v_user_id
  LEFT JOIN LATERAL (
    SELECT m.id, m.message_text, m.user_id, m.created_at
    FROM public.messages m
    WHERE m.conversation_id = c.id
      AND m.is_deleted = FALSE
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
  WHERE (p_type IS NULL OR c.type = p_type)
  ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id UUID, p_type TEXT DEFAULT NULL)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type VARCHAR(10),
  conversation_title TEXT,
  course_id UUID,
  created_at TIMESTAMPTZ,
  last_message_id UUID,
  last_message_text TEXT,
  last_message_user_id UUID,
  last_message_user_name TEXT,
  last_message_created_at TIMESTAMPTZ,
  participants_count BIGINT,
  other_user_name TEXT,
  other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Cannot read conversations for another user';
  END IF;

  RETURN QUERY
  SELECT * FROM public.get_user_conversations(p_type);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_course_group_members(p_course_id UUID)
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  user_avatar TEXT,
  role TEXT,
  is_banned BOOLEAN,
  banned_reason TEXT,
  conversation_title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_conversation_id UUID;
  v_conversation_title TEXT;
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  SELECT id, title
  INTO v_conversation_id, v_conversation_title
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    cp.user_id,
    p.name AS user_name,
    p.avatar_url AS user_avatar,
    cp.role,
    COALESCE(cp.is_banned, FALSE) AS is_banned,
    cp.ban_reason AS banned_reason,
    v_conversation_title AS conversation_title
  FROM public.conversation_participants cp
  JOIN public.profiles p ON p.id = cp.user_id
  WHERE cp.conversation_id = v_conversation_id
  ORDER BY cp.role ASC, p.name ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_course_group_title(p_course_id UUID, p_title TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  UPDATE public.conversations
  SET title = NULLIF(BTRIM(p_title), ''),
      updated_at = NOW()
  WHERE course_id = p_course_id
    AND type = 'multi';
END;
$$;

CREATE OR REPLACE FUNCTION public.manage_course_group_member(
  p_course_id UUID,
  p_target_user_id UUID,
  p_action TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_conversation_id UUID;
BEGIN
  IF NOT public.can_manage_course(p_course_id) THEN
    RAISE EXCEPTION 'Not authorized to manage this course group';
  END IF;

  SELECT id
  INTO v_conversation_id
  FROM public.conversations
  WHERE course_id = p_course_id
    AND type = 'multi'
  LIMIT 1;

  IF v_conversation_id IS NULL THEN
    RAISE EXCEPTION 'Course group not found';
  END IF;

  IF p_action = 'remove' THEN
    DELETE FROM public.conversation_participants
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'ban' THEN
    UPDATE public.conversation_participants
    SET is_banned = TRUE,
        ban_reason = p_reason,
        banned_at = NOW(),
        banned_by = auth.uid()
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'unban' THEN
    UPDATE public.conversation_participants
    SET is_banned = FALSE,
        ban_reason = NULL,
        banned_at = NULL,
        banned_by = NULL
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'admin' THEN
    UPDATE public.conversation_participants
    SET role = 'admin'
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSIF p_action = 'member' THEN
    UPDATE public.conversation_participants
    SET role = 'member'
    WHERE conversation_id = v_conversation_id
      AND user_id = p_target_user_id;
  ELSE
    RAISE EXCEPTION 'Invalid action: %', p_action;
  END IF;
END;
$$;

-- ============================================================
-- 5. Storage policy tightening for clearly-owned buckets
-- ============================================================

DROP POLICY IF EXISTS "Authenticated manage avatars" ON storage.objects;
DROP POLICY IF EXISTS "System write certificates" ON storage.objects;
DROP POLICY IF EXISTS "Users manage own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Admins write certificates" ON storage.objects;

CREATE POLICY "Users manage own avatars"
ON storage.objects
FOR ALL
USING (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

CREATE POLICY "Admins write certificates"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'certificates' AND public.is_admin());

-- ============================================================
-- 6. Function execution grants
-- ============================================================

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- Helpers used inside RLS policies need execute permission for table reads.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'is_instructor',
        'is_admin',
        'is_enrolled',
        'is_conversation_participant',
        'can_manage_course',
        'current_profile_sensitive_state'
      )
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon, authenticated', r.oid::regprocedure);
  END LOOP;
END;
$$;

-- App-facing RPCs. Each function below must still enforce its own auth checks.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'add_phone_to_auth_user',
        'create_profile_for_phone_auth',
        'create_enrollment',
        'validate_coupon',
        'update_lesson_progress',
        'issue_certificate',
        'get_or_create_single_conversation',
        'get_or_create_course_conversation',
        'get_user_conversations',
        'get_course_group_members',
        'update_course_group_title',
        'manage_course_group_member',
        'get_instructor_forum_courses',
        'set_course_group_enabled',
        'process_refund',
        'get_instructor_dashboard_stats',
        'get_instructor_revenue_chart',
        'get_instructor_enrollments_chart',
        'submit_withdraw_request',
        'toggle_section_published',
        'schedule_section_publish',
        'toggle_lesson_published',
        'schedule_lesson_publish',
        'increment_enrolled_count',
        'decrement_enrolled_count',
        'increment_quiz_questions',
        'decrement_quiz_questions',
        'submit_quiz_attempt',
        'get_unread_notifications_count',
        'mark_all_notifications_read'
      )
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.oid::regprocedure);
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO service_role;
