# Phase 01: Setup Notification Service
Status: ⬜ Pending
Dependencies: None

## Objective
Tích hợp thư viện `flutter_local_notifications` và cài đặt cấu hình ban đầu cho Android và iOS để có thể đẩy thông báo offline.

## Requirements
### Functional
- Thêm `flutter_local_notifications` và `timezone` vào `pubspec.yaml`.
- Tạo một lớp service hoặc provider `LocalNotificationService` để khởi tạo cấu hình (Android initialization settings, iOS initialization settings).
- Yêu cầu quyền thông báo (request notifications permission) khi người dùng mở ứng dụng hoặc khi cấu hình nhận lương.
- Thiết lập kênh thông báo (Notification Channel) cho Android (mặc định: `salary_reminder_channel` với độ ưu tiên cao).

### Non-Functional
- Khởi tạo timezone database để lập lịch chính xác theo giờ địa phương (`tz.initializeTimeZones()`).

## Implementation Steps
1. [ ] Cập nhật `pubspec.yaml` để thêm `flutter_local_notifications` và `timezone`.
2. [ ] Chạy `flutter pub get` để tải các thư viện mới.
3. [ ] Cấu hình Android Manifest (`AndroidManifest.xml`) để cấp các quyền cần thiết:
   - `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (đối với Android 13+)
   - `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>` (để khôi phục lịch nhắc nhở sau khi khởi động lại máy)
   - Cấu hình receiver để lắng nghe sự kiện boot completed.
4. [ ] Cấu hình iOS (`AppDelegate.swift`) để đăng ký notification settings nếu cần.
5. [ ] Tạo file `lib/core/services/notification_service.dart` định nghĩa lớp `NotificationService` sử dụng mẫu Singleton hoặc Riverpod provider.
6. [ ] Gọi phương thức khởi tạo `NotificationService.initialize()` trong hàm `main()` của ứng dụng.

## Files to Create/Modify
- `mobile/pubspec.yaml` - Thêm thư viện.
- `mobile/android/app/src/main/AndroidManifest.xml` - Khai báo quyền & receiver.
- `mobile/lib/core/services/notification_service.dart` [NEW] - Viết service khởi tạo và quản lý thông báo.
- `mobile/lib/main.dart` - Gọi khởi tạo dịch vụ thông báo khi chạy ứng dụng.

## Test Criteria
- [ ] Ứng dụng build thành công sau khi thêm package mới.
- [ ] Khi khởi động ứng dụng lần đầu tiên (hoặc khi bật tính năng), hệ thống hỏi quyền gửi thông báo trên thiết bị/emulator.
- [ ] Kiểm tra log khởi tạo thành công không gặp lỗi timezone hoặc plugin.

---
Next Phase: [Phase 02: Schedule Notification Logic](file:///d:/git/fin-goal/plans/260621-2230-local-salary-reminder/phase-02-schedule-notification-logic.md)
