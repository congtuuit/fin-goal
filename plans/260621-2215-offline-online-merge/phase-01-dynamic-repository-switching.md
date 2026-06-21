# Phase 01: Dynamic Repository Switching
Status: ⬜ Pending
Dependencies: None

## Objective
Enable the application to dynamically choose between Local and Online repository implementations based on the active user session type, instead of relying on a compile-time static flag.

## Requirements
### Functional
- When the logged-in user is a local guest (user ID is `'local_user_id'`), all data operations (profile, goals, monthly records, scenario queries) must use SharedPreferences local repositories.
- When the user is authenticated via Supabase (user ID != `'local_user_id'`), all operations must use online Supabase repositories.
- **Hide Guest Mode for returning users:** If the device has previously logged in via Google (check flag `has_logged_in_with_google` in SharedPreferences), hide the Guest name input and the "Bắt đầu ngay" button to prevent data collision.

### Non-Functional
- Smooth transition: Switching repositories must trigger Riverpod provider invalidation so that the UI immediately loads data from the correct data source.

## Implementation Steps
1. [ ] Modify repository provider definitions in `lib/features/profile/presentation/providers/profile_provider.dart` to watch `currentUserProvider` and return the appropriate repository implementation based on user type.
2. [ ] Modify repository provider definitions in `lib/features/goals/presentation/providers/goals_provider.dart` (or similar) to watch `currentUserProvider` and return the appropriate repository implementation.
3. [ ] Modify repository provider definitions in `lib/features/scenarios/presentation/providers/scenarios_provider.dart` (or similar) to watch `currentUserProvider` and return the appropriate repository implementation.
4. [ ] Save a flag `has_logged_in_with_google` in SharedPreferences upon successful Google Login.
5. [ ] Update `LoginPage` to check `has_logged_in_with_google` and conditionally hide the name input form, only displaying the "Đăng nhập bằng Google" button.
6. [ ] Verify that navigating to settings, profile, and dashboard pages dynamically changes depending on the login mode without requiring an app rebuild.

## Files to Create/Modify
- `mobile/lib/features/profile/presentation/providers/profile_provider.dart` - Modify repository resolver
- `mobile/lib/features/goals/presentation/providers/goals_provider.dart` (or goals related providers) - Modify repository resolver
- `mobile/lib/features/scenarios/presentation/providers/scenarios_provider.dart` (or scenarios related providers) - Modify repository resolver
- `mobile/lib/features/auth/presentation/pages/login_page.dart` - Hide Guest UI based on the Google flag
- `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart` - Set the Google login flag in SharedPreferences

## Test Criteria
- [ ] Log in with a name (Guest Mode) -> verify that profile and goals are fetched/saved to SharedPreferences.
- [ ] Log in with Google -> verify that profile and goals are fetched/saved to Supabase, and the `has_logged_in_with_google` flag is saved.
- [ ] Log out -> verify that the Guest Mode UI is now hidden on the login screen, and only the Google Login button is shown.
- [ ] Log out -> verify that data source bindings are correctly reset.

---
Next Phase: [Phase 02: Data Synchronization Service](file:///d:/git/fin-goal/plans/260621-2215-offline-online-merge/phase-02-data-sync-mechanism.md)
