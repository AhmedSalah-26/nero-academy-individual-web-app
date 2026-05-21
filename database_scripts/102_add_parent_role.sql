-- ============================================================
-- Migration: Add 'parent' role to profiles table
-- Version: 1.0.2 | January 2026
-- ============================================================

-- Update the role check constraint to include 'parent'
ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles 
ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('student', 'instructor', 'parent', 'admin'));

-- Add parent-specific fields to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS linked_student_ids UUID[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS parent_verification_status TEXT DEFAULT 'pending' 
  CHECK (parent_verification_status IN ('pending', 'verified', 'rejected'));

-- Create index for parent role
CREATE INDEX IF NOT EXISTS idx_profiles_parent_role 
ON profiles(role) WHERE role = 'parent';

-- Create parent_student_links table for parent-student relationships
CREATE TABLE IF NOT EXISTS parent_student_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  relationship TEXT DEFAULT 'parent' CHECK (relationship IN ('parent', 'guardian', 'other')),
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_id, student_id)
);

CREATE INDEX idx_parent_student_links_parent ON parent_student_links(parent_id);
CREATE INDEX idx_parent_student_links_student ON parent_student_links(student_id);

-- RLS Policies for parent_student_links
ALTER TABLE parent_student_links ENABLE ROW LEVEL SECURITY;

-- Parents can view their own links
CREATE POLICY "Parents can view own links" ON parent_student_links
  FOR SELECT USING (auth.uid() = parent_id);

-- Parents can create links (pending verification)
CREATE POLICY "Parents can create links" ON parent_student_links
  FOR INSERT WITH CHECK (auth.uid() = parent_id);

-- Students can view links where they are the student
CREATE POLICY "Students can view links to them" ON parent_student_links
  FOR SELECT USING (auth.uid() = student_id);

-- Students can verify/update links to them
CREATE POLICY "Students can verify links" ON parent_student_links
  FOR UPDATE USING (auth.uid() = student_id);

COMMENT ON TABLE parent_student_links IS 'Links between parent accounts and student accounts for progress monitoring';
