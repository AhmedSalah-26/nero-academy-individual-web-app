-- Fix flash sale logic:
-- 1) Enforce valid timed window and price
-- 2) Normalize fields when flash sale is disabled
-- 3) Auto-clean expired flash sales with a helper function

-- Clean already expired flash sales once.
UPDATE public.courses
SET
  is_flash_sale = FALSE,
  flash_sale_price = NULL,
  flash_sale_start = NULL,
  flash_sale_end = NULL,
  badge = CASE
    WHEN badge IN ('فلاش سيل', 'Flash Sale') THEN NULL
    ELSE badge
  END
WHERE is_flash_sale = TRUE
  AND flash_sale_end IS NOT NULL
  AND flash_sale_end <= NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'courses_flash_sale_window_chk'
  ) THEN
    ALTER TABLE public.courses
      ADD CONSTRAINT courses_flash_sale_window_chk
      CHECK (
        NOT is_flash_sale OR
        (
          flash_sale_start IS NOT NULL AND
          flash_sale_end IS NOT NULL AND
          flash_sale_end > flash_sale_start
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'courses_flash_sale_price_chk'
  ) THEN
    ALTER TABLE public.courses
      ADD CONSTRAINT courses_flash_sale_price_chk
      CHECK (
        NOT is_flash_sale OR
        (
          price > 0 AND
          flash_sale_price IS NOT NULL AND
          flash_sale_price >= 0 AND
          flash_sale_price < price
        )
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.normalize_course_flash_sale_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- If flash sale is disabled, clear all timed-sale fields.
  IF COALESCE(NEW.is_flash_sale, FALSE) = FALSE THEN
    NEW.flash_sale_price := NULL;
    NEW.flash_sale_start := NULL;
    NEW.flash_sale_end := NULL;
    IF NEW.badge IN ('فلاش سيل', 'Flash Sale') THEN
      NEW.badge := NULL;
    END IF;
    RETURN NEW;
  END IF;

  -- Ensure flash sale badge exists when timed sale is enabled.
  IF NEW.badge IS NULL OR btrim(NEW.badge) = '' THEN
    NEW.badge := 'فلاش سيل';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_course_flash_sale ON public.courses;
CREATE TRIGGER trg_normalize_course_flash_sale
BEFORE INSERT OR UPDATE ON public.courses
FOR EACH ROW
EXECUTE FUNCTION public.normalize_course_flash_sale_fields();

-- Optional helper for cron jobs:
-- SELECT public.expire_finished_flash_sales();
CREATE OR REPLACE FUNCTION public.expire_finished_flash_sales()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_updated_count integer;
BEGIN
  UPDATE public.courses
  SET
    is_flash_sale = FALSE,
    flash_sale_price = NULL,
    flash_sale_start = NULL,
    flash_sale_end = NULL,
    badge = CASE
      WHEN badge IN ('فلاش سيل', 'Flash Sale') THEN NULL
      ELSE badge
    END
  WHERE is_flash_sale = TRUE
    AND flash_sale_end IS NOT NULL
    AND flash_sale_end <= NOW();

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

NOTIFY pgrst, 'reload schema';
