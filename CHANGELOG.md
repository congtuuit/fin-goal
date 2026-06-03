# Changelog

Dự án: **fin-goal (Financial Simulator App)**

## [2026-06-03]
### Added
- **MVP Offline Hoàn Toàn & Định hướng Hybrid**:
  - Tạo Interface cho Auth, Goals, Scenarios, Records để tách biệt logic.
  - Hiện thực `LocalAuthRepositoryImpl`, `LocalGoalRepositoryImpl`, `LocalScenarioRepositoryImpl`, `LocalRecordRepositoryImpl` sử dụng SharedPreferences.
  - Tạo màn hình **SettingsPage** (`settings_page.dart`) để cấu hình chọn AI Provider (Gemini / OpenAI), nhập API Key và Model lưu cục bộ.
  - Hiện thực `DirectClientAiService` gọi API trực tiếp (client-side) sử dụng `HttpClient` core của Dart.
- **Tài liệu hướng dẫn**:
  - Thêm tài liệu hướng dẫn cấu hình môi trường [docs/environment_setup.md](file:///d:/git/fin-goal/docs/environment_setup.md).
- **Kịch bản tự động hóa**:
  - Tạo script tự động hóa build/release bằng Node.js (`scripts/build_app.js`), file `build.bat` cho Windows và file `build.sh` cho macOS/Linux.

### Changed
- Hiệu chỉnh `LoginPage` tự động đổi sang giao diện nhập Tên cá nhân đơn giản khi ở chế độ offline.
- Cập nhật `what_if_page.dart` kết nối AI thật và xử lý lỗi trực quan hướng dẫn người dùng điền Key.
- Hiệu chỉnh logic điều hướng (Router Guard) và kết nối nút bấm Settings trên Dashboard.
- Nâng cấp Android Gradle Plugin (AGP) lên `9.0.1` để tương thích tốt hơn với thư viện hiện đại.
- Cấu hình Gradle bỏ qua Kotlin Gradle Plugin (`android.builtInKotlin=false` trong `gradle.properties`) nhằm tránh lỗi tương thích của một số plugins cũ.
- Chuyển đổi cú pháp Riverpod 3.0 (bỏ hậu tố `Notifier` tự động sinh trên các UI file).
- Định dạng lại sơ đồ Mermaid trong `app_flow_chart.md` (bọc chuỗi có ký tự đặc biệt, dùng `<br/>`, chia các subgraph trực quan).

### Removed
- Tạm thời gỡ bỏ package `sentry_flutter` do lỗi không tương thích với AGP 9 (`Cannot query provider`).

### Fixed
- Sửa lỗi kẹt màn hình Splash (loading vô tận) bằng cách hiệu chỉnh logic điều hướng trong `lib/app/router/app_router.dart`.
- Tự động focus input (FocusNode) trong các bước Onboarding.
- Sửa lỗi văng app khi gọi `createProfile` và `saveRecord` (treo loading) do Provider bị huỷ (autoDispose) khi đang await async logic. Áp dụng `@Riverpod(keepAlive: true)`.
- Sửa lỗi vòng lặp chuyển trang (navigation loop) gây giật màn hình khi bấm Back từ màn hình chọn mục tiêu (Dashboard hiển thị Empty State thay vì ép chuyển trang).
- Fix lỗi UI giật cục (layout shift) khi thanh Slider làm chuỗi text "Tháng 12/2026" vắt dòng, bằng cách bọc `FittedBox`.
- Gỡ bỏ `.animate()` ở các component cập nhật liên tục (khi kéo slider) để tránh quá tải render.

### Added
- Tính năng Lịch sử Check-in:
  - Nút "Check-in tháng này" tự đổi thành "Sửa Check-in" nếu đã cập nhật.
  - Hiển thị danh sách lịch sử dưới Dashboard.
  - Bấm vào thẻ lịch sử để sửa số tiền cũ mượt mà.
