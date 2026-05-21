-- ============================================================
-- 340: CREATE LEVELS TABLE
-- ============================================================
-- Creates a separate levels table for dynamic level management
-- Migrates existing level data from courses table
-- ============================================================

-- =============================================
-- STEP 1: Create levels table
-- =============================================
CREATE TABLE IF NOT EXISTS public.levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description_ar TEXT,
  description_en TEXT,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_levels_active ON public.levels(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_levels_order ON public.levels(display_order);

-- =============================================
-- STEP 2: Insert default levels
-- =============================================
INSERT INTO public.levels (name_ar, name_en, slug, description_ar, description_en, display_order, is_active)
VALUES
  ('مبتدئ', 'Beginner', 'beginner', 'مناسب للمبتدئين بدون خبرة سابقة', 'Suitable for beginners with no prior experience', 1, true),
  ('متوسط', 'Intermediate', 'intermediate', 'يتطلب معرفة أساسية بالموضوع', 'Requires basic knowledge of the subject', 2, true),
  ('متقدم', 'Advanced', 'advanced', 'للمتقدمين ذوي الخبرة', 'For advanced learners with experience', 3, true),
  ('جميع المستويات', 'All Levels', 'all_levels', 'مناسب لجميع المستويات', 'Suitable for all levels', 4, true)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- STEP 3: Add level_id column to courses table
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'courses'
      AND column_name = 'level_id'
  ) THEN
    ALTER TABLE public.courses
      ADD COLUMN level_id UUID REFERENCES public.levels(id);
  END IF;
END $$;

-- =============================================
-- STEP 4: Migrate existing level data
-- =============================================
-- Map old level enum values to new level_id
UPDATE public.courses c
SET level_id = l.id
FROM public.levels l
WHERE c.level = l.slug
  AND c.level_id IS NULL;

-- =============================================
-- STEP 5: Make level_id NOT NULL after migration
-- =============================================
DO $$
BEGIN
  -- Check if all courses have level_id
  IF NOT EXISTS (
    SELECT 1 FROM public.courses WHERE level_id IS NULL
  ) THEN
    ALTER TABLE public.courses
      ALTER COLUMN level_id SET NOT NULL;
  END IF;
END $$;

-- =============================================
-- STEP 6: Enable RLS on levels table
-- =============================================
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;

-- Everyone can view active levels
DROP POLICY IF EXISTS "Anyone can view active levels" ON public.levels;
CREATE POLICY "Anyone can view active levels"
  ON public.levels
  FOR SELECT
  USING (is_active = true OR auth.uid() IS NOT NULL);

-- Only admins can insert/update/delete levels
DROP POLICY IF EXISTS "Admins can manage levels" ON public.levels;
CREATE POLICY "Admins can manage levels"
  ON public.levels
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =============================================
-- STEP 7: Grant permissions
-- =============================================
GRANT SELECT ON public.levels TO authenticated, anon;
GRANT ALL ON public.levels TO authenticated;

-- =============================================
-- ✅ MIGRATION COMPLETE!
-- =============================================
-- Old: courses.level (TEXT enum)
-- New: courses.level_id (UUID FK to levels table)
-- Note: Keep old 'level' column for backward compatibility
--       Can be removed after full migration
-- =============================================
