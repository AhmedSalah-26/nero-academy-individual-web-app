-- Check triggers on enrollments table
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'enrollments';

-- Check the create_enrollment function source code to see if it inserts earnings
SELECT pg_get_functiondef('create_enrollment'::regproc);
