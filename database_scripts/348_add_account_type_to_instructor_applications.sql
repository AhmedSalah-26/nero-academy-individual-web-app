-- 348_add_account_type_to_instructor_applications.sql
-- Adds account_type support for manual admin-created requests.
-- Keeps public submissions restricted to instructor requests.

ALTER TABLE public.instructor_applications
  ADD COLUMN IF NOT EXISTS account_type TEXT NOT NULL DEFAULT 'instructor'
  CHECK (account_type IN ('student', 'instructor', 'parent', 'admin'));

CREATE INDEX IF NOT EXISTS idx_instructor_applications_account_type
  ON public.instructor_applications(account_type);

DROP POLICY IF EXISTS "Anyone can submit instructor applications"
  ON public.instructor_applications;
CREATE POLICY "Anyone can submit instructor applications"
  ON public.instructor_applications
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND account_type = 'instructor'
  );

DROP POLICY IF EXISTS "Admins can insert instructor applications"
  ON public.instructor_applications;
CREATE POLICY "Admins can insert instructor applications"
  ON public.instructor_applications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );
