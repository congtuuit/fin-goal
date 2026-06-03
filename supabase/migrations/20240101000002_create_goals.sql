-- Migration: 002_create_goals
-- Description: User financial goals — supports both preset and custom goals

CREATE TABLE IF NOT EXISTS goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type            VARCHAR(50) NOT NULL,   -- 'emergency_fund' | 'car' | 'house' | 'wedding' | 'travel' | 'retirement' | 'custom'
    name            VARCHAR(255) NOT NULL,
    target_amount   BIGINT NOT NULL CHECK (target_amount > 0), -- VND
    emoji           VARCHAR(10),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE, -- Free tier: only 1 active primary goal
    sort_order      INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Index for fast user goal lookup
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_user_active ON goals(user_id, is_active);

-- RLS
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals"
    ON goals FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
