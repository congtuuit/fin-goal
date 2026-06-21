-- Migration: 006_add_delete_user_rpc
-- Description: Create delete_user function to allow users to delete their own accounts

CREATE OR REPLACE FUNCTION delete_user()
RETURNS void AS $$
BEGIN
    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
