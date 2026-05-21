-- Fix Coupons Policies - Allow instructors and admins to view all coupons
-- ============================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
DROP POLICY IF EXISTS "Instructors can manage own coupons" ON coupons;
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;

-- Create new policies
-- 1. Anyone can view active coupons (for students)
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT 
  USING (
    is_active = TRUE 
    AND is_suspended = FALSE 
    AND start_date <= NOW() 
    AND (end_date IS NULL OR end_date > NOW())
  );

-- 2. Instructors can view all coupons (for admin panel)
CREATE POLICY "Instructors can view all coupons" ON coupons FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('instructor', 'admin')
    )
  );

-- 3. Instructors can insert their own coupons
CREATE POLICY "Instructors can insert own coupons" ON coupons 
  FOR INSERT
  WITH CHECK (instructor_id = auth.uid());

-- 4. Instructors can update their own coupons
CREATE POLICY "Instructors can update own coupons" ON coupons 
  FOR UPDATE
  USING (instructor_id = auth.uid());

-- 5. Instructors can delete their own coupons
CREATE POLICY "Instructors can delete own coupons" ON coupons 
  FOR DELETE
  USING (instructor_id = auth.uid());

-- 6. Admins can manage all coupons
CREATE POLICY "Admins can manage all coupons" ON coupons 
  FOR ALL 
  USING (is_admin());

-- Update coupon_categories and coupon_courses policies
DROP POLICY IF EXISTS "Instructors can manage coupon categories" ON coupon_categories;
DROP POLICY IF EXISTS "Admins can manage coupon categories" ON coupon_categories;

CREATE POLICY "Instructors can manage coupon categories" ON coupon_categories 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_categories.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage coupon categories" ON coupon_categories 
  FOR ALL 
  USING (is_admin());

DROP POLICY IF EXISTS "Instructors can manage coupon courses" ON coupon_courses;
DROP POLICY IF EXISTS "Admins can manage coupon courses" ON coupon_courses;

CREATE POLICY "Instructors can manage coupon courses" ON coupon_courses 
  FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_courses.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage coupon courses" ON coupon_courses 
  FOR ALL 
  USING (is_admin());

-- Update coupon_usages policies
DROP POLICY IF EXISTS "Instructors can view coupon usages" ON coupon_usages;
DROP POLICY IF EXISTS "Admins can view all coupon usages" ON coupon_usages;

CREATE POLICY "Instructors can view own coupon usages" ON coupon_usages 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM coupons 
      WHERE coupons.id = coupon_usages.coupon_id 
      AND coupons.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all coupon usages" ON coupon_usages 
  FOR SELECT 
  USING (is_admin());
