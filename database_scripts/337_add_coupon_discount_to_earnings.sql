-- =============================================
-- 337: ADD COUPON DISCOUNT TO EARNINGS_TRANSACTIONS
-- =============================================
-- Adds coupon_discount column to track per-item coupon discount
-- Net instructor earnings = amount - commission - coupon_discount
-- =============================================

ALTER TABLE public.earnings_transactions
ADD COLUMN IF NOT EXISTS coupon_discount NUMERIC DEFAULT 0;

COMMENT ON COLUMN public.earnings_transactions.coupon_discount IS
  'Per-item coupon discount (proportionally distributed from cart coupon)';
