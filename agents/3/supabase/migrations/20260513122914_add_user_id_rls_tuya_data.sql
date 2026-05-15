-- Migration: Add user_id to tuya_data and set up RLS
-- Choice: Option D (Add owner_id, authenticated only, admin bypass)

-- 1. Add user_id column if it doesn't exist
ALTER TABLE public.tuya_data
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid();

-- 2. Enable RLS
ALTER TABLE public.tuya_data ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow service role" ON public.tuya_data;
DROP POLICY IF EXISTS "Users can view own tuya data" ON public.tuya_data;
DROP POLICY IF EXISTS "Users can insert own tuya data" ON public.tuya_data;

-- 4. Policies
CREATE POLICY "Users can view own tuya data" ON public.tuya_data
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tuya data" ON public.tuya_data
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 5. Index for RLS performance
CREATE INDEX IF NOT EXISTS idx_tuya_data_user_id ON public.tuya_data(user_id);

-- 6. Documentation
COMMENT ON COLUMN public.tuya_data.user_id IS 'The owner of the device data, linked to auth.users';
