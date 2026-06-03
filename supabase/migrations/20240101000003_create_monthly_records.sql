-- Migration: 003_create_monthly_records
-- Description: Monthly actual savings data — enables Plan Reliability scoring

CREATE TABLE IF NOT EXISTS monthly_records (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id             UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    record_month        DATE NOT NULL,              -- First day of the month (e.g. 2024-01-01)
    planned_savings     BIGINT NOT NULL,            -- VND — what the plan said
    actual_savings      BIGINT,                     -- VND — what user actually saved (NULL if not submitted yet)
    variance_percent    DECIMAL(6, 2),              -- Auto-calculated: (actual - planned) / planned * 100
    plan_reliability    DECIMAL(5, 2),              -- Snapshot of reliability score at this point
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, goal_id, record_month)
);

-- Auto-calculate variance when actual_savings is set
CREATE OR REPLACE FUNCTION calculate_variance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.actual_savings IS NOT NULL AND NEW.planned_savings > 0 THEN
        NEW.variance_percent = ((NEW.actual_savings - NEW.planned_savings)::DECIMAL / NEW.planned_savings) * 100;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_calculate_variance
    BEFORE INSERT OR UPDATE ON monthly_records
    FOR EACH ROW
    EXECUTE FUNCTION calculate_variance();

CREATE TRIGGER update_monthly_records_updated_at
    BEFORE UPDATE ON monthly_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_monthly_records_user_goal ON monthly_records(user_id, goal_id);
CREATE INDEX idx_monthly_records_month ON monthly_records(record_month);

-- RLS
ALTER TABLE monthly_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own monthly records"
    ON monthly_records FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
