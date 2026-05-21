-- ============================================================
-- Fix RLS for Quiz Attempts - Simple Version
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Enable RLS
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies on quiz_attempts
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT policyname FROM pg_policies WHERE tablename = 'quiz_attempts'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON quiz_attempts', pol.policyname);
  END LOOP;
END $$;

-- 3. Create simple policies that allow users to manage their attempts
CREATE POLICY "quiz_attempts_select" ON quiz_attempts
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "quiz_attempts_insert" ON quiz_attempts
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "quiz_attempts_update" ON quiz_attempts
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- 4. Verify policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'quiz_attempts';
