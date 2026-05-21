-- =====================================================
-- 313_normalize_instructor_profile_schema.sql
-- Goal:
-- 1) Keep instructor-specific data in instructor_profiles
-- 2) Remove duplicated instructor columns from profiles
-- =====================================================

BEGIN;

-- A) Normalize payout_method first to satisfy existing CHECK constraint.
-- Current allowed values (from migration 259): 'instapay', 'wallet'.
UPDATE public.instructor_profiles
SET payout_method = 'wallet'
WHERE payout_method IS NOT NULL
  AND payout_method NOT IN ('instapay', 'wallet');

ALTER TABLE public.instructor_profiles
  ALTER COLUMN payout_method SET DEFAULT 'wallet';

-- 0) Deduplicate instructor_profiles by instructor_id (keep most recently updated row).
WITH ranked AS (
  SELECT
    id,
    instructor_id,
    ROW_NUMBER() OVER (
      PARTITION BY instructor_id
      ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
    ) AS rn
  FROM public.instructor_profiles
  WHERE instructor_id IS NOT NULL
)
DELETE FROM public.instructor_profiles ip
USING ranked r
WHERE ip.id = r.id
  AND r.rn > 1;

-- 1) Ensure uniqueness on instructor_id.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'instructor_profiles_instructor_id_key'
      AND conrelid = 'public.instructor_profiles'::regclass
  ) THEN
    ALTER TABLE public.instructor_profiles
      ADD CONSTRAINT instructor_profiles_instructor_id_key UNIQUE (instructor_id);
  END IF;
END $$;

-- 2) Ensure each instructor has a row in instructor_profiles.
INSERT INTO public.instructor_profiles (
  instructor_id,
  display_name,
  avatar_url,
  payout_method,
  is_active,
  created_at,
  updated_at
)
SELECT
  p.id,
  COALESCE(NULLIF(BTRIM(p.name), ''), 'Instructor'),
  p.avatar_url,
  'wallet',
  COALESCE(p.is_active, TRUE),
  NOW(),
  NOW()
FROM public.profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1
    FROM public.instructor_profiles ip
    WHERE ip.instructor_id = p.id
  );

-- 3) Migrate/merge legacy instructor fields from profiles -> instructor_profiles.
UPDATE public.instructor_profiles ip
SET
  display_name = COALESCE(
    NULLIF(BTRIM(ip.display_name), ''),
    NULLIF(BTRIM(p.name), ''),
    ip.display_name
  ),
  avatar_url = COALESCE(
    NULLIF(BTRIM(ip.avatar_url), ''),
    NULLIF(BTRIM(p.avatar_url), ''),
    ip.avatar_url
  ),
  headline_ar = COALESCE(
    NULLIF(BTRIM(ip.headline_ar), ''),
    NULLIF(BTRIM(p.headline_ar), ''),
    NULLIF(BTRIM(p.headline), ''),
    ip.headline_ar
  ),
  headline_en = COALESCE(
    NULLIF(BTRIM(ip.headline_en), ''),
    NULLIF(BTRIM(p.headline_en), ''),
    ip.headline_en
  ),
  bio_ar = COALESCE(
    NULLIF(BTRIM(ip.bio_ar), ''),
    NULLIF(BTRIM(p.bio_ar), ''),
    NULLIF(BTRIM(p.bio), ''),
    ip.bio_ar
  ),
  bio_en = COALESCE(
    NULLIF(BTRIM(ip.bio_en), ''),
    NULLIF(BTRIM(p.bio_en), ''),
    ip.bio_en
  ),
  expertise = CASE
    WHEN ip.expertise IS NULL OR cardinality(ip.expertise) = 0 THEN p.expertise
    ELSE ip.expertise
  END,
  social_links = COALESCE(
    ip.social_links,
    p.social_links,
    NULLIF(
      jsonb_strip_nulls(
        jsonb_build_object(
          'website', NULLIF(BTRIM(p.website), ''),
          'linkedin', NULLIF(BTRIM(p.linkedin), ''),
          'twitter', NULLIF(BTRIM(p.twitter), '')
        )
      ),
      '{}'::jsonb
    )
  ),
  is_verified = COALESCE(ip.is_verified, p.is_verified_instructor, FALSE),
  updated_at = NOW()
FROM public.profiles p
WHERE p.id = ip.instructor_id
  AND p.role = 'instructor';

-- 4) Keep profiles.name non-empty for instructors (fallback from display_name).
UPDATE public.profiles p
SET
  name = COALESCE(NULLIF(BTRIM(p.name), ''), NULLIF(BTRIM(ip.display_name), ''), p.name),
  updated_at = NOW()
FROM public.instructor_profiles ip
WHERE ip.instructor_id = p.id
  AND p.role = 'instructor'
  AND (p.name IS NULL OR BTRIM(p.name) = '');

-- 5) Drop duplicated instructor-only columns from profiles.
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline_ar;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline_en;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio_ar;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio_en;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS expertise;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS social_links;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS is_verified_instructor;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS headline;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS bio;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS website;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS linkedin;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS twitter;

COMMIT;
