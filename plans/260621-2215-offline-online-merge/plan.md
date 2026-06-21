# Plan: Merge Offline Mode with Online Mode (Hybrid Architecture)
Created: 2026-06-21T22:15:00+07:00
Status: 🟡 In Progress

## Overview
Currently, the application toggles between Offline (local SharedPreferences) and Online (Supabase Cloud) mode statically via the `AppConfig.isOffline` compile-time flag.
This plan transforms this behavior into a **dynamic hybrid architecture** where:
1. **Runtime Mode Switching:** The app dynamically resolves whether to use Local or Online repositories based on the user's active session state (Guest/Name login vs. Google Login).
2. **Data Sync Service:** When a Guest user logs in with Google, any locally created data (Financial Profile, Goals, Monthly Savings Records, and Scenario Queries) is automatically uploaded and merged into their new Supabase account, and then the local guest cache is cleared.

## Tech Stack
- Frontend: Flutter & Riverpod (dynamic Repository providers)
- Backend: Supabase Auth & DB (Online repositories)
- Storage: SharedPreferences (Local repositories)

## Phases

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 01 | Dynamic Repository Switching | ⬜ Pending | 0% |
| 02 | Data Synchronization Service | ⬜ Pending | 0% |
| 03 | Testing & Verification | ⬜ Pending | 0% |

## Quick Commands
- Start Phase 1: `/code phase-01`
- Check progress: `/next`
- Save context: `/save-brain`
