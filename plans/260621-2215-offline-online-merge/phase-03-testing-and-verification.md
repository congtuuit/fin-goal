# Phase 03: Testing & Verification
Status: ⬜ Pending
Dependencies: Phase 02

## Objective
Verify the end-to-end user experience of starting locally as a guest, creating goals, signing in with Google, merging data to Supabase Cloud, and continuing the online game session.

## Requirements
- No data loss during transition.
- App immediately renders updated goals and profile fetched from online database.
- The UI handles the transition loading state cleanly.

## Implementation Steps
1. [ ] Perform manual testing on Android emulator starting from Guest Mode.
2. [ ] Trigger Google Sign-In and watch log outputs to ensure `DataSyncService` runs and logs its progress.
3. [ ] Verify database state in Supabase Studio dashboard to ensure correct row mappings.
4. [ ] Run integration test case to simulate offline mode and online transition.

## Test Criteria
- [ ] Profile and goals are synchronized seamlessly.
- [ ] No duplicate goals are created on repeat sign-ins.
- [ ] Onboarding state is correctly mapped.
