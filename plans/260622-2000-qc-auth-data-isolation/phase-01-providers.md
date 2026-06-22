# Phase 01: Riverpod Providers Optimization
Status: ⬜ Pending
Dependencies: None

## Objective
Đồng bộ hóa các Riverpod Providers với Auth State để tự động giải phóng cache/dữ liệu cũ và tải dữ liệu mới khi thay đổi tài khoản.

## Requirements
### Functional
- [ ] Tự động cập nhật danh sách Goals khi User thay đổi.
- [ ] Tự động cập nhật kịch bản What-If và Monthly Records khi User thay đổi.
- [ ] Tự động cập nhật thông tin Financial Profile khi User thay đổi.
- [ ] Tự động tải lại Game State khi thay đổi User.

## Implementation Steps
1. [ ] Cập nhật `mobile/lib/features/goals/presentation/providers/goal_provider.dart` để watch `goalRepositoryProvider` trong `GoalsNotifier.build`.
2. [ ] Cập nhật `mobile/lib/features/scenarios/presentation/providers/scenario_provider.dart` để watch `scenarioRepositoryProvider` / `recordRepositoryProvider`.
3. [ ] Cập nhật `mobile/lib/features/profile/presentation/providers/profile_provider.dart` để watch `profileRepositoryProvider`.
4. [ ] Cập nhật `mobile/lib/features/cashflow_game/presentation/providers/game_provider.dart` để watch `currentUserProvider`.

## Files to Create/Modify
- `mobile/lib/features/goals/presentation/providers/goal_provider.dart`
- `mobile/lib/features/scenarios/presentation/providers/scenario_provider.dart`
- `mobile/lib/features/profile/presentation/providers/profile_provider.dart`
- `mobile/lib/features/cashflow_game/presentation/providers/game_provider.dart`

---
Next Phase: [Phase 02: Guest Account Deletion](file:///d:/git/fin-goal/plans/260622-2000-qc-auth-data-isolation/phase-02-auth-delete.md)
