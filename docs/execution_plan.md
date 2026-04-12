-- STEP-BY-STEP EXECUTION PLAN FOR SUPABASE DATABASE RESTORATION
-- Execute these files in order to restore your database completely

-- STEP 1: Test the basic tables first
-- Execute: test_schema.sql
-- This will create just the musteriler and triko_takip tables with test data
-- and the view to verify everything works

-- STEP 2: Execute the comprehensive schema
-- Execute: comprehensive_database_schema.sql
-- This will create ALL tables, constraints, indexes, RLS policies, triggers, and views

-- STEP 3: Add additional test data
-- Execute: test_data.sql
-- This will populate all tables with sample data for testing

-- STEP 4: Verify the database
-- After executing the above files, run these queries in Supabase SQL editor:

-- Check all tables exist:
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check the view works:
SELECT * FROM musteri_siparis_ozet;

-- Check critical tables have data:
SELECT COUNT(*) FROM musteriler;
SELECT COUNT(*) FROM triko_takip;
SELECT COUNT(*) FROM personel;
SELECT COUNT(*) FROM tedarikci;
SELECT COUNT(*) FROM faturalar;

-- STEP 5: Test the Flutter app
-- Run the Flutter app and test each module:
-- - Model listing page
-- - Customer management
-- - Supplier management
-- - Invoice management
-- - Personnel management
-- - Stock management

-- TROUBLESHOOTING:
-- If you get an error about missing tables, check which table is missing
-- and ensure it's included in the comprehensive schema file.

-- If you get RLS policy errors, you may need to temporarily disable RLS:
-- ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- If you get permission errors, ensure your user has the correct permissions
-- or execute the SQL as the postgres user.
