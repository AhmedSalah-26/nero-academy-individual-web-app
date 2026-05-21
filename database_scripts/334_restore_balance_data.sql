-- =============================================
-- 334: Restore instructor_balance data
-- =============================================

-- Re-insert balance for all instructors who have courses
INSERT INTO public.instructor_balance (instructor_id, available_balance, pending_balance, total_withdrawn, total_earnings)
SELECT 
  p.id,
  0,  -- available_balance (will be recalculated)
  0,  -- pending_balance
  0,  -- total_withdrawn
  0   -- total_earnings
FROM public.profiles p
WHERE p.role = 'instructor'
ON CONFLICT (instructor_id) DO NOTHING;

-- Recalculate total_earnings from enrollments (actual sales)
UPDATE public.instructor_balance ib
SET total_earnings = COALESCE(sub.total, 0),
    available_balance = COALESCE(sub.total, 0)
FROM (
  SELECT 
    e.instructor_id,
    SUM(e.price * 0.7) as total  -- 70% instructor share
  FROM public.enrollments e
  WHERE e.price > 0 
    AND e.instructor_id IS NOT NULL
  GROUP BY e.instructor_id
) sub
WHERE ib.instructor_id = sub.instructor_id;

-- Account for already withdrawn amounts from withdraw_requests
UPDATE public.instructor_balance ib
SET total_withdrawn = COALESCE(sub.total_withdrawn, 0),
    available_balance = ib.total_earnings - COALESCE(sub.total_withdrawn, 0)
FROM (
  SELECT 
    user_id,
    SUM(amount) as total_withdrawn
  FROM public.withdraw_requests
  WHERE status IN ('approved', 'paid')
  GROUP BY user_id
) sub
WHERE ib.instructor_id = sub.user_id;

-- Account for pending withdrawals
UPDATE public.instructor_balance ib
SET pending_balance = COALESCE(sub.total_pending, 0),
    available_balance = ib.available_balance - COALESCE(sub.total_pending, 0)
FROM (
  SELECT 
    user_id,
    SUM(amount) as total_pending
  FROM public.withdraw_requests
  WHERE status = 'pending'
  GROUP BY user_id
) sub
WHERE ib.instructor_id = sub.user_id;

-- Make sure available_balance is never negative
UPDATE public.instructor_balance
SET available_balance = 0
WHERE available_balance < 0;

-- Also recreate earnings_transactions from enrollments history
INSERT INTO public.earnings_transactions (user_id, course_id, course_name, amount, commission, status, source_type, created_at)
SELECT 
  e.instructor_id,
  e.course_id,
  COALESCE(c.title_ar, 'Unknown Course'),
  e.price,
  e.price * 0.3,  -- 30% platform commission
  'available',
  'course_sale',
  e.enrolled_at
FROM public.enrollments e
LEFT JOIN public.courses c ON c.id = e.course_id
WHERE e.price > 0 
  AND e.instructor_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Show results
SELECT 
  ib.instructor_id,
  p.name as instructor_name,
  ib.available_balance,
  ib.pending_balance,
  ib.total_earnings,
  ib.total_withdrawn
FROM public.instructor_balance ib
LEFT JOIN public.profiles p ON p.id = ib.instructor_id
ORDER BY ib.total_earnings DESC;
