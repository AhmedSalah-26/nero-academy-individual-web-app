-- =============================================
-- 352: AUTO CREATE EARNINGS ON ENROLLMENT
-- =============================================
-- Creates a trigger to automatically create earnings transaction
-- and update instructor balance when a student enrolls in a course
-- =============================================

-- Drop existing trigger and function if exists
DROP TRIGGER IF EXISTS trigger_auto_create_earnings ON public.enrollments;
DROP FUNCTION IF EXISTS public.auto_create_earnings_transaction() CASCADE;

-- Create function to handle enrollment earnings
CREATE OR REPLACE FUNCTION public.auto_create_earnings_transaction()
RETURNS TRIGGER AS $$
DECLARE
  v_instructor_id UUID;
  v_course_name TEXT;
  v_revenue_share NUMERIC(5,2);
  v_instructor_share NUMERIC(12,2);
  v_platform_commission NUMERIC(12,2);
BEGIN
  -- Only process paid enrollments with active status
  IF NEW.price > 0 AND NEW.status = 'active' THEN
    
    -- Get instructor_id and course details
    SELECT 
      c.instructor_id,
      COALESCE(c.title_ar, c.title_en, 'Unknown Course'),
      70.0  -- Default revenue share
    INTO 
      v_instructor_id,
      v_course_name,
      v_revenue_share
    FROM courses c
    WHERE c.id = NEW.course_id;
    
    -- Try to get revenue_share from instructors table if it exists
    IF EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'instructors'
    ) THEN
      SELECT COALESCE(revenue_share, 70.0)
      INTO v_revenue_share
      FROM instructors
      WHERE user_id = v_instructor_id;
    END IF;
    
    -- If instructor not found, skip
    IF v_instructor_id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Calculate shares
    v_instructor_share := NEW.price * (v_revenue_share / 100.0);
    v_platform_commission := NEW.price - v_instructor_share;
    
    -- Check if earnings transaction already exists for this enrollment
    IF NOT EXISTS (
      SELECT 1 FROM earnings_transactions 
      WHERE course_id = NEW.course_id 
        AND user_id = v_instructor_id
        AND created_at = NEW.enrolled_at
        AND amount = NEW.price
    ) THEN
      
      -- Create earnings transaction
      INSERT INTO earnings_transactions (
        user_id,
        course_id,
        course_name,
        amount,
        commission,
        status,
        source_type,
        created_at
      ) VALUES (
        v_instructor_id,
        NEW.course_id,
        v_course_name,
        NEW.price,
        v_platform_commission,
        'available',
        'course_sale',
        COALESCE(NEW.enrolled_at, NOW())
      );
      
      -- Update instructor balance
      -- Check if balance record exists
      IF EXISTS (
        SELECT 1 FROM instructor_balance WHERE instructor_id = v_instructor_id
      ) THEN
        -- Update existing balance
        UPDATE instructor_balance
        SET
          available_balance = available_balance + v_instructor_share,
          total_earnings = total_earnings + v_instructor_share,
          updated_at = NOW()
        WHERE instructor_id = v_instructor_id;
      ELSE
        -- Create new balance record
        INSERT INTO instructor_balance (
          instructor_id,
          available_balance,
          pending_balance,
          total_withdrawn,
          total_earnings,
          updated_at
        ) VALUES (
          v_instructor_id,
          v_instructor_share,
          0,
          0,
          v_instructor_share,
          NOW()
        );
      END IF;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on enrollments table
CREATE TRIGGER trigger_auto_create_earnings
  AFTER INSERT OR UPDATE ON public.enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_earnings_transaction();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.auto_create_earnings_transaction() TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.auto_create_earnings_transaction IS 'Automatically creates earnings transaction and updates instructor balance when student enrolls';

-- =============================================
-- ✅ DONE: Auto earnings trigger created
-- =============================================

