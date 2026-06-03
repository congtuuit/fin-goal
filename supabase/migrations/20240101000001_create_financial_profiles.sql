-- Migration: 001_create_financial_profiles
-- Description: User financial profile — core data for all calculations

CREATE TABLE IF NOT EXISTS financial_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    age             INT NOT NULL CHECK (age BETWEEN 16 AND 100),
    monthly_income  BIGINT NOT NULL CHECK (monthly_income > 0),    -- VND
    fixed_expenses  BIGINT NOT NULL CHECK (fixed_expenses >= 0),   -- VND
    current_savings BIGINT NOT NULL DEFAULT 0 CHECK (current_savings >= 0), -- VND
    salary_date     INT NOT NULL CHECK (salary_date BETWEEN 1 AND 31),
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_financial_profiles_updated_at
    BEFORE UPDATE ON financial_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS: Users can only access their own profile
ALTER TABLE financial_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON financial_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
    ON financial_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
    ON financial_profiles FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
