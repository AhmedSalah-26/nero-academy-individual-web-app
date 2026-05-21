-- Migration: Remove flash_sale_price column from courses table
-- Date: 2026-02-12
-- Reason: Flash sale no longer uses a separate price field.
--         The discount_price is used for both permanent and time-limited (flash sale) discounts.
--         Flash sale role is now only to make the discount time-limited via flash_sale_start/end.

ALTER TABLE courses DROP COLUMN IF EXISTS flash_sale_price;
