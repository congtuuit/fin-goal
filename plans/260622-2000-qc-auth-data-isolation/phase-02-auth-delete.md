# Phase 02: Guest Account Deletion
Status: ⬜ Pending
Dependencies: [Phase 01: Riverpod Providers Optimization](file:///d:/git/fin-goal/plans/260622-2000-qc-auth-data-isolation/phase-01-providers.md)

## Objective
Cho phép người dùng Guest xóa tài khoản và dọn dẹp sạch dữ liệu cục bộ trong SharedPreferences khi hành động này xảy ra.

## Requirements
### Functional
- [ ] Khi click "Xóa tài khoản" ở Guest mode, toàn bộ dữ liệu guest (goals, records, scenarios, profile, local_username, logged_in_user) phải được xóa sạch.
- [ ] Trả về kết quả thành công và đẩy `null` vào Auth Stream để đưa người dùng trở lại màn hình Welcome/Login.

## Implementation Steps
1. [ ] Cập nhật `deleteAccount()` trong `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart` để check `getCurrentUser()?.id == 'local_user_id'`.
2. [ ] Thực hiện xóa các key SharedPreferences tương ứng.

## Files to Create/Modify
- `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`

---
Next Phase: [Phase 03: Testing & Verification](file:///d:/git/fin-goal/plans/260622-2000-qc-auth-data-isolation/phase-03-testing.md)
