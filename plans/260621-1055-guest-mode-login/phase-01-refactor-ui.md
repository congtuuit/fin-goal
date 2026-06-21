# Phase 01: Refactor Login UI
Status: ⬜ Pending
Dependencies: None

## Objective
Tạm ẩn giao diện đăng nhập và đăng ký bằng Email/Password. Chỉ giữ lại nút Đăng nhập bằng Google.

## Requirements
### Functional
- [ ] Ẩn form nhập Email và Password ở `LoginPage`
- [ ] Ẩn form đăng ký ở `RegisterPage` (hoặc chặn điều hướng tới trang này)
- [ ] Đảm bảo nút Đăng nhập Google vẫn hoạt động đúng

## Implementation Steps
1. [ ] Cập nhật `LoginPage`: Xóa/Comment các widget TextField cho Email và Password.
2. [ ] Xóa/Comment dòng code điều hướng tới `RegisterPage`.

## Files to Modify
- `mobile/lib/features/auth/presentation/pages/login_page.dart`
- `mobile/lib/features/auth/presentation/pages/register_page.dart` (nếu cần)

---
Next Phase: Phase 02 Onboarding
