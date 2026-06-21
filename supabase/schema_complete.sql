-- Complete Database Schema for Fin Goal (Supabase)
-- Includes all migrations and latest Dart model column requirements.

-- ============================================================================
-- 1. Helper Functions & Triggers
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Tables & Triggers
-- ============================================================================

-- Table: financial_profiles
CREATE TABLE IF NOT EXISTS financial_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    age             INT NOT NULL CHECK (age BETWEEN 16 AND 100),
    monthly_income  BIGINT NOT NULL CHECK (monthly_income > 0),    -- VND
    fixed_expenses  BIGINT NOT NULL CHECK (fixed_expenses >= 0),   -- VND
    current_savings BIGINT NOT NULL DEFAULT 0 CHECK (current_savings >= 0), -- VND
    salary_date     INT NOT NULL CHECK (salary_date BETWEEN 1 AND 31),
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    purchased_goal_slots TIMESTAMPTZ[] NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE OR REPLACE TRIGGER update_financial_profiles_updated_at
    BEFORE UPDATE ON financial_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Table: goals
CREATE TABLE IF NOT EXISTS goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type            VARCHAR(50) NOT NULL,   -- 'emergency_fund' | 'car' | 'house' | 'wedding' | 'travel' | 'retirement' | 'custom'
    name            VARCHAR(255) NOT NULL,
    target_amount   BIGINT NOT NULL CHECK (target_amount > 0), -- VND
    emoji           VARCHAR(10),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT NOT NULL DEFAULT 0,
    current_savings BIGINT NOT NULL DEFAULT 0 CHECK (current_savings >= 0),
    monthly_saving  BIGINT NOT NULL DEFAULT 0 CHECK (monthly_saving >= 0),
    is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
    status          VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Table: monthly_records
CREATE TABLE IF NOT EXISTS monthly_records (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id             UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    record_month        DATE NOT NULL,
    planned_savings     BIGINT NOT NULL,
    actual_savings      BIGINT,
    variance_percent    DECIMAL(6, 2),
    plan_reliability    DECIMAL(5, 2),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, goal_id, record_month)
);

CREATE OR REPLACE TRIGGER update_monthly_records_updated_at
    BEFORE UPDATE ON monthly_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION calculate_variance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.actual_savings IS NOT NULL AND NEW.planned_savings > 0 THEN
        NEW.variance_percent = ((NEW.actual_savings - NEW.planned_savings)::DECIMAL / NEW.planned_savings) * 100;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_calculate_variance
    BEFORE INSERT OR UPDATE ON monthly_records
    FOR EACH ROW
    EXECUTE FUNCTION calculate_variance();

-- Table: scenario_queries
CREATE TABLE IF NOT EXISTS scenario_queries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id             UUID REFERENCES goals(id) ON DELETE SET NULL,
    item_name           VARCHAR(255) NOT NULL,
    item_cost           BIGINT NOT NULL,
    impact_months       DECIMAL(5, 1),
    best_case_months    INT,
    expected_months     INT,
    worst_case_months   INT,
    ai_explanation      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: user_subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tier                VARCHAR(20) NOT NULL DEFAULT 'free',
    revenuecat_id       VARCHAR(255),
    expires_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE OR REPLACE TRIGGER update_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION create_default_subscription()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscriptions (user_id, tier)
    VALUES (NEW.id, 'free')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_subscription();

-- ============================================================================
-- 3. Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user_active ON goals(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_monthly_records_user_goal ON monthly_records(user_id, goal_id);
CREATE INDEX IF NOT EXISTS idx_monthly_records_month ON monthly_records(record_month);
CREATE INDEX IF NOT EXISTS idx_scenario_queries_user ON scenario_queries(user_id);

-- ============================================================================
-- 4. Row Level Security (RLS) Policies
-- ============================================================================

-- financial_profiles
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

-- goals
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals"
    ON goals FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- monthly_records
ALTER TABLE monthly_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own monthly records"
    ON monthly_records FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- scenario_queries
ALTER TABLE scenario_queries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own scenario queries"
    ON scenario_queries FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- user_subscriptions
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription"
    ON user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role can update subscriptions"
    ON user_subscriptions FOR ALL
    USING (auth.role() = 'service_role');
