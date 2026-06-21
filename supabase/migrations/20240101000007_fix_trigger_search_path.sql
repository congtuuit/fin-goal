-- Migration: 007_fix_trigger_search_path
-- Description: Fully qualify public.user_subscriptions in create_default_subscription trigger function to fix database error saving new user during sign-up.

CREATE OR REPLACE FUNCTION create_default_subscription()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_subscriptions (user_id, tier)
    VALUES (NEW.id, 'free')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
