-- RLS Policies for uretim_kayitlari table
-- This file contains all necessary Row Level Security policies for production records

-- First, let's check what sequences and tables exist
SELECT 'Available sequences:' as info;
SELECT sequence_name, sequence_schema 
FROM information_schema.sequences 
WHERE sequence_name LIKE '%uretim%' OR sequence_name LIKE '%atolye%'
ORDER BY sequence_name;

SELECT 'Available tables:' as info;
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_name IN ('uretim_kayitlari', 'atolyeler')
ORDER BY table_name;

-- Enable RLS on uretim_kayitlari table
ALTER TABLE uretim_kayitlari ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for all users" ON uretim_kayitlari;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON uretim_kayitlari;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON uretim_kayitlari;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON uretim_kayitlari;

-- Create comprehensive RLS policies for uretim_kayitlari

-- SELECT Policy: Allow all authenticated users to read production records
CREATE POLICY "Enable read access for all users" ON uretim_kayitlari 
FOR SELECT 
USING (true);

-- INSERT Policy: Allow authenticated users to insert production records
CREATE POLICY "Enable insert access for authenticated users" ON uretim_kayitlari 
FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- UPDATE Policy: Allow authenticated users to update production records
CREATE POLICY "Enable update access for authenticated users" ON uretim_kayitlari 
FOR UPDATE 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- DELETE Policy: Allow authenticated users to delete production records
CREATE POLICY "Enable delete access for authenticated users" ON uretim_kayitlari 
FOR DELETE 
USING (auth.role() = 'authenticated');

-- Enable RLS on related tables if not already enabled
ALTER TABLE atolyeler ENABLE ROW LEVEL SECURITY;
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;

-- Create policies for atolyeler table if they don't exist
DO $$ 
BEGIN
    -- Check if policies exist for atolyeler
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'atolyeler' 
        AND policyname = 'Enable read access for all users'
    ) THEN
        CREATE POLICY "Enable read access for all users" ON atolyeler 
        FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'atolyeler' 
        AND policyname = 'Enable insert access for authenticated users'
    ) THEN
        CREATE POLICY "Enable insert access for authenticated users" ON atolyeler 
        FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'atolyeler' 
        AND policyname = 'Enable update access for authenticated users'
    ) THEN
        CREATE POLICY "Enable update access for authenticated users" ON atolyeler 
        FOR UPDATE 
        USING (auth.role() = 'authenticated')
        WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'atolyeler' 
        AND policyname = 'Enable delete access for authenticated users'
    ) THEN
        CREATE POLICY "Enable delete access for authenticated users" ON atolyeler 
        FOR DELETE USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- Grant necessary permissions
GRANT ALL ON uretim_kayitlari TO authenticated;
GRANT ALL ON atolyeler TO authenticated;

-- Grant sequence permissions (only if sequences exist)
DO $$
BEGIN
    -- Check for uretim_kayitlari sequence variations
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'uretim_kayitlari_id_seq') THEN
        GRANT USAGE ON SEQUENCE uretim_kayitlari_id_seq TO authenticated;
    ELSIF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name LIKE '%uretim_kayitlari%') THEN
        -- Find and grant the actual sequence name
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || (
            SELECT sequence_name 
            FROM information_schema.sequences 
            WHERE sequence_name LIKE '%uretim_kayitlari%' 
            LIMIT 1
        ) || ' TO authenticated';
    END IF;
    
    -- Check for atolyeler sequence
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'atolyeler_id_seq') THEN
        GRANT USAGE ON SEQUENCE atolyeler_id_seq TO authenticated;
    ELSIF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name LIKE '%atolyeler%') THEN
        -- Find and grant the actual sequence name
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || (
            SELECT sequence_name 
            FROM information_schema.sequences 
            WHERE sequence_name LIKE '%atolyeler%' 
            LIMIT 1
        ) || ' TO authenticated';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Continue even if sequence grants fail
        RAISE NOTICE 'Some sequence grants may have failed, but this is not critical: %', SQLERRM;
END $$;

-- Verify policies are created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('uretim_kayitlari', 'atolyeler')
ORDER BY tablename, policyname;
