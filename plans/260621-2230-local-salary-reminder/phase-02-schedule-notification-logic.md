# Phase 02: Schedule Notification Logic
Status: ⬜ Pending
Dependencies: [Phase 01: Setup Notification Service](file:///d:/git/fin-goal/plans/260621-2230-local-salary-reminder/phase-01-setup-notification-service.md)

## Objective
Xây dựng logic tự động lập lịch nhắc nhở hàng tháng dựa trên ngày nhận lương của người dùng và điều kiện kiểm tra mục tiêu chưa hoàn thành.

## Requirements
### Functional
- Đọc ngày nhận lương từ `FinancialProfile` (`salaryDate`, thường từ 1 đến 31).
- Khi người dùng cập nhật thông tin hồ sơ tài chính (hoặc khi bắt đầu session mới):
  - Lập lịch thông báo cục bộ định kỳ hàng tháng vào ngày `salaryDate` lúc 09:00 sáng.
  - Sử dụng phương thức `zonedSchedule` với `DateTimeComponents.dayOfMonth` để lặp lại hàng tháng.
- Xử lý điều kiện động:
  - Do offline push notification lập lịch trước, ta không thể check realtime lúc thông báo nổ xem có goal nào chưa hoàn thành hay không (trừ phi dùng background fetch phức tạp).
  - Giải pháp tối ưu & nhẹ nhàng: Mỗi khi danh sách goals thay đổi (thêm, sửa, xóa, hoàn thành goal), ứng dụng sẽ tự động cập nhật hoặc hủy/lập lại lịch thông báo:
    - Nếu có ít nhất 1 goal chưa hoàn thành -> Lập lịch thông báo nhắc nhở ngày nhận lương tiếp theo.
    - Nếu tất cả goals đều đã hoàn thành -> Hủy (cancel) lịch thông báo này để không làm phiền người dùng.

### Non-Functional
- Đảm bảo ID của thông báo nhắc lương là duy nhất và cố định (ví dụ: `1001`) để ghi đè lịch cũ thay vì tạo nhiều thông báo trùng lặp.
- Nội dung thông báo thân thiện:
  - Tiêu đề: `Hôm nay là ngày nhận lương! 💸`
  - Nội dung: `Đã đến lúc cập nhật và kiểm kê lại kế hoạch mục tiêu tài chính của bạn rồi. Vào app ngay nhé!`

## Implementation Steps
1. [ ] Cập nhật `NotificationService` để thêm hàm `scheduleSalaryReminder({required int salaryDay, required bool hasIncompleteGoals})`.
2. [ ] Trong hàm `scheduleSalaryReminder`:
   - Kiểm tra `hasIncompleteGoals`. Nếu `false`, gọi `flutterLocalNotificationsPlugin.cancel(SALARY_REMINDER_ID)`.
   - Nếu `true`, tính toán thời gian cho ngày nhận lương tiếp theo (nếu ngày nhận lương của tháng này đã qua thì lập lịch sang tháng sau).
   - Thiết lập lập lịch hàng tháng: `zonedSchedule` sử dụng `matchDateTimeComponents: DateTimeComponents.dayOfMonth`.
3. [ ] Tích hợp trigger lập lịch:
   - Trong `ProfileNotifier` hoặc nơi lưu trữ profile: mỗi khi cập nhật profile (đặc biệt thay đổi ngày nhận lương), gọi cập nhật lịch.
   - Trong `GoalNotifier` hoặc nơi cập nhật danh sách mục tiêu: mỗi khi trạng thái mục tiêu thay đổi (đặc biệt khi hoàn thành hoặc thêm mục tiêu mới), gọi cập nhật lịch.
4. [ ] Khôi phục lịch sau khi khởi động máy: Cấu hình BroadcastReceiver trên Android để khi nhận sự kiện `BOOT_COMPLETED`, ứng dụng sẽ tự động tính toán lại và lập lịch lại thông báo (nếu cần).

## Files to Create/Modify
- `mobile/lib/core/services/notification_service.dart` - Thêm logic lập lịch/hủy lịch.
- `mobile/lib/features/profile/presentation/providers/profile_provider.dart` - Kích hoạt lập lịch lại khi cập nhật profile.
- `mobile/lib/features/goals/presentation/providers/goals_provider.dart` - Kích hoạt lập lịch lại khi cập nhật danh sách/trạng thái goals.

## Test Criteria
- [ ] Khi cập nhật hồ sơ với ngày nhận lương mới, kiểm tra xem log có ghi nhận việc lập lịch thông báo mới.
- [ ] Khi hoàn thành tất cả các mục tiêu, kiểm tra log xác nhận lịch thông báo đã bị hủy.
- [ ] Thêm một nút test nhanh (Debug button) để lập lịch thông báo sau 5 giây để kiểm thử xem thông báo có đẩy lên màn hình thiết bị thật/emulator hay không.

---
Next Phase: [Phase 03: Testing & Verification](file:///d:/git/fin-goal/plans/260621-2230-local-salary-reminder/phase-03-testing-and-verification.md)
