-- ============================================================
-- Function: Update Certificate URL
-- This function updates the certificate_url after PDF is uploaded
-- ============================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS update_certificate_url(UUID, TEXT);

-- Create the function
CREATE OR REPLACE FUNCTION update_certificate_url(
  p_certificate_id UUID,
  p_certificate_url TEXT
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_certificate RECORD;
BEGIN
  -- Get certificate and verify ownership
  SELECT * INTO v_certificate
  FROM certificates
  WHERE id = p_certificate_id AND user_id = v_user_id;
  
  IF v_certificate IS NULL THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Certificate not found or access denied'
    );
  END IF;
  
  -- Update certificate URL
  UPDATE certificates 
  SET certificate_url = p_certificate_url
  WHERE id = p_certificate_id;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'certificate_id', p_certificate_id,
    'certificate_url', p_certificate_url
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false, 
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_certificate_url(UUID, TEXT) TO authenticated;
