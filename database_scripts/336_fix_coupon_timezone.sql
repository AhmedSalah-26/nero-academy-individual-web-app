-- =============================================
-- 336: FIX COUPON TIMEZONE OFFSET
-- =============================================
-- Problem: start_date and end_date were stored with local time
-- as if it were UTC, creating a +2 hour offset.
-- Fix: Subtract 2 hours from all affected dates.
-- =============================================

-- Fix start_date (subtract 2 hours to correct the offset)
UPDATE public.coupons
SET start_date = start_date - INTERVAL '2 hours'
WHERE start_date IS NOT NULL;

-- Fix end_date (subtract 2 hours to correct the offset)
UPDATE public.coupons
SET end_date = end_date - INTERVAL '2 hours'
WHERE end_date IS NOT NULL;

-- Also fix banners if affected
UPDATE public.banners
SET start_date = start_date - INTERVAL '2 hours'
WHERE start_date IS NOT NULL;

UPDATE public.banners
SET end_date = end_date - INTERVAL '2 hours'
WHERE end_date IS NOT NULL;

-- Verify
SELECT id, code, start_date, end_date, is_active
FROM public.coupons
ORDER BY created_at DESC
LIMIT 20;
