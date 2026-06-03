# Changelog

Dự án: **fin-goal (Financial Simulator App)**

## [2026-06-03]
### Added
- Thêm tài liệu tổng quan hệ thống `docs/architecture/system_overview.md`.
- Thêm sơ đồ luồng điều hướng ứng dụng định dạng Mermaid trong `docs/architecture/app_flow_chart.md`.

### Changed
- Nâng cấp Android Gradle Plugin (AGP) lên `9.0.1` để tương thích tốt hơn với thư viện hiện đại.
- Cấu hình Gradle bỏ qua Kotlin Gradle Plugin (`android.builtInKotlin=false` trong `gradle.properties`) nhằm tránh lỗi tương thích của một số plugins cũ.
- Chuyển đổi cú pháp Riverpod 3.0 (bỏ hậu tố `Notifier` tự động sinh trên các UI file).
- Định dạng lại sơ đồ Mermaid trong `app_flow_chart.md` (bọc chuỗi có ký tự đặc biệt, dùng `<br/>`, chia subgraph rõ ràng).

### Removed
- Tạm thời gỡ bỏ package `sentry_flutter` do lỗi không tương thích với AGP 9 (`Cannot query provider`).

### Fixed
- Sửa lỗi kẹt màn hình Splash (loading vô tận) bằng cách hiệu chỉnh logic điều hướng (Router Guard) trong `lib/app/router/app_router.dart`.
