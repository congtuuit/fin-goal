# Phase 02: Data Synchronization Service
Status: ⬜ Pending
Dependencies: Phase 01

## Objective
Implement a synchronization service that automatically reads local guest data and pushes/merges it into Supabase when the user signs in with a Google account.

## Requirements
### Functional
- Read local financial profile, goals, monthly records, and scenario queries from local repositories.
- If local guest data exists, insert it into Supabase under the newly authenticated user's ID.
- Handle duplicates gracefully (e.g. merge goals by type/name, upsert profile).
- Clear the local SharedPreferences guest data cache upon successful synchronization to avoid duplicate uploads.

### Non-Functional
- Sync should run in the background upon successful Google login.
- Provide feedback to the user if sync is in progress or completed.

## Implementation Steps
1. [ ] Create `DataSyncRepository` interface and `DataSyncRepositoryImpl` to manage the cross-repository sync flow.
2. [ ] Define a `DataSyncProvider` that manages the synchronization state (Idle, Syncing, Success, Error).
3. [ ] Trigger the sync process inside `signInWithGoogle` callback in `AuthNotifier` immediately after a successful Supabase authentication.
4. [ ] Clear local data using `LocalAuthRepository.deleteAccount()` or individual local repository cleanup methods after sync succeeds.

## Files to Create/Modify
- `mobile/lib/features/auth/data/repositories/data_sync_repository_impl.dart` - [NEW] Manage the actual synchronization logic
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` - Modify to trigger sync on Google Sign-In success

## Test Criteria
- [ ] Create a local profile and a local goal in Guest Mode.
- [ ] Log in with Google.
- [ ] Verify that the local profile and goal are uploaded to Supabase under the user's UUID.
- [ ] Check SharedPreferences to confirm the local guest cache has been cleared.

---
Next Phase: [Phase 03: Testing & Verification](file:///d:/git/fin-goal/plans/260621-2215-offline-online-merge/phase-03-testing-and-verification.md)
