-- Migration: 004_create_scenario_queries
-- Description: Logs all "what-if" decisions the user runs

CREATE TABLE IF NOT EXISTS scenario_queries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id             UUID REFERENCES goals(id) ON DELETE SET NULL,
    item_name           VARCHAR(255) NOT NULL,      -- e.g. "iPhone 18 Pro"
    item_cost           BIGINT NOT NULL,             -- VND
    impact_months       DECIMAL(5, 1),              -- How many months delayed (can be 0 if savings covers it)
    best_case_months    INT,
    expected_months     INT,
    worst_case_months   INT,
    ai_explanation      TEXT,                       -- NULL in V1, populated in V2
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scenario_queries_user ON scenario_queries(user_id);

-- RLS
ALTER TABLE scenario_queries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own scenario queries"
    ON scenario_queries FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Migration: 005_create_user_subscriptions
-- Description: Subscription tiers managed via RevenueCat webhook

CREATE TABLE IF NOT EXISTS user_subscriptions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tier                VARCHAR(20) NOT NULL DEFAULT 'free', -- 'free' | 'premium' | 'family'
    revenuecat_id       VARCHAR(255),
    expires_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TRIGGER update_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Auto-create free subscription when user signs up
CREATE OR REPLACE FUNCTION create_default_subscription()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscriptions (user_id, tier)
    VALUES (NEW.id, 'free')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_subscription();

-- RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription"
    ON user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can update subscription (for RevenueCat webhook)
CREATE POLICY "Service role can update subscriptions"
    ON user_subscriptions FOR ALL
    USING (auth.role() = 'service_role');
