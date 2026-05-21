-- Fix Categories Policies - Allow admins to view all categories
-- ============================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view active categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;

-- Create new policies
-- 1. Anyone can view active categories (for students)
CREATE POLICY "Anyone can view active categories" ON categories 
  FOR SELECT 
  USING (is_active = TRUE);

-- 2. Admins can view all categories (including inactive)
CREATE POLICY "Admins can view all categories" ON categories 
  FOR SELECT 
  USING (is_admin());

-- 3. Admins can manage all categories
CREATE POLICY "Admins can insert categories" ON categories 
  FOR INSERT 
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update categories" ON categories 
  FOR UPDATE 
  USING (is_admin());

CREATE POLICY "Admins can delete categories" ON categories 
  FOR DELETE 
  USING (is_admin());
