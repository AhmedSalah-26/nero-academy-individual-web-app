-- 347_create_instructor_applications.sql
-- Create instructor applications flow:
-- - Public/anon can submit instructor requests
-- - Only admins can view/review requests

CREATE TABLE IF NOT EXISTS public.instructor_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes TEXT,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_instructor_applications_status
  ON public.instructor_applications(status);

CREATE INDEX IF NOT EXISTS idx_instructor_applications_created_at
  ON public.instructor_applications(created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_instructor_applications_pending_email_unique
  ON public.instructor_applications (LOWER(email))
  WHERE status = 'pending';

DROP TRIGGER IF EXISTS update_instructor_applications_updated_at
  ON public.instructor_applications;

CREATE TRIGGER update_instructor_applications_updated_at
  BEFORE UPDATE ON public.instructor_applications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.instructor_applications ENABLE ROW LEVEL SECURITY;

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
  );

DROP POLICY IF EXISTS "Admins can view instructor applications"
  ON public.instructor_applications;
CREATE POLICY "Admins can view instructor applications"
  ON public.instructor_applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update instructor applications"
  ON public.instructor_applications;
CREATE POLICY "Admins can update instructor applications"
  ON public.instructor_applications
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can delete instructor applications"
  ON public.instructor_applications;
CREATE POLICY "Admins can delete instructor applications"
  ON public.instructor_applications
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

GRANT INSERT ON public.instructor_applications TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.instructor_applications TO authenticated;

