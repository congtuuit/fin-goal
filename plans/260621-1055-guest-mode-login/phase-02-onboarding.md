# Phase 02: Luồng Onboarding
Status: ⬜ Pending
Dependencies: Phase 01

## Objective
Hợp nhất luồng mở app: Dù ở chế độ Online hay Offline, đều yêu cầu user nhập tên để tạo phiên Guest Mode và vào Dashboard trải nghiệm app.

## Requirements
### Functional
- [ ] Sửa đổi logic Splash/Auth Routing để luôn dẫn tới trang Onboarding (Nhập tên) nếu chưa có AuthData.
- [ ] Sử dụng `LocalAuthRepositoryImpl` hoặc một hàm tương tự trên `AuthNotifier` để lưu phiên Guest.

## Implementation Steps
1. [ ] Cập nhật `SplashPage` / Router để chuyển người dùng sang `LoginPage` hoặc `OnboardingPage` nhập tên thay vì buộc họ phải qua Auth bằng Supabase.
2. [ ] Đảm bảo luồng Guest cập nhật state thành công để vào app.

## Files to Modify
- `mobile/lib/app/routes/app_router.dart`
- `mobile/lib/features/auth/presentation/pages/splash_page.dart`
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart`

---
Next Phase: Phase 03 Bottom Sheet
