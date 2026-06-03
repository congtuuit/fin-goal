# Phase 02: Offline Auth Module

Status: ✅ Complete
Dependencies: [Phase 01: Design Architecture & Interfaces](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-01-architecture.md)

## Objective
Hiện thực hóa module đăng nhập ngoại tuyến bằng SharedPreferences. Cho phép người dùng nhập tên tại LoginPage để bỏ qua xác thực và lưu session cục bộ.

## Implementation Steps
1. [x] Tạo file `local_auth_service.dart` kế thừa từ `AuthService`. Sử dụng `shared_preferences` để lưu và lấy tên của người dùng đăng nhập cục bộ.
2. [x] Đăng ký `LocalAuthService` vào hệ thống Dependency Injection (GetIt/Injectable) làm AuthService mặc định.
3. [x] Cấu hình lại Router Guard trong `app_router.dart`:
   - Kiểm tra thông tin người dùng từ `AuthService` (nếu đã có tên -> chuyển tiếp vào Dashboard, nếu chưa -> chuyển về LoginPage).
4. [x] Thay đổi giao diện `login_page.dart`:
   - Bỏ trường nhập Email/Password.
   - Thêm trường nhập Tên người dùng (Username) và nút "Bắt đầu". Khi nhấn sẽ lưu tên thông qua `AuthService` và điều hướng về Dashboard.

## Files to Create/Modify
- `mobile/lib/core/services/local_auth_service.dart` - [NEW]
- `mobile/lib/app/router/app_router.dart` - [MODIFY]
- `mobile/lib/features/auth/presentation/pages/login_page.dart` - [MODIFY]

## Test Criteria
- [ ] Khi khởi động app lần đầu (không có dữ liệu trong SharedPreferences), app tự động dừng ở LoginPage.
- [ ] Nhập tên "Tuấn" bấm Bắt đầu -> Chuyển vào Dashboard thành công.
- [ ] Tắt app đi bật lại -> App tự động bỏ qua LoginPage và đi thẳng vào Dashboard.
- [ ] Ở Dashboard hiển thị lời chào "Xin chào, Tuấn!".

---
Next Phase: [Phase 03: Local Database (Isar Setup)](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-03-local-database.md)
