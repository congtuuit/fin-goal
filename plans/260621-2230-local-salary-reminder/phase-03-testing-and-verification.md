# Phase 03: Testing & Verification
Status: ⬜ Pending
Dependencies: [Phase 02: Schedule Notification Logic](file:///d:/git/fin-goal/plans/260621-2230-local-salary-reminder/phase-02-schedule-notification-logic.md)

## Objective
Kiểm thử tính năng lập lịch nhắc nhở cục bộ trong môi trường giả lập và thiết bị thật để đảm bảo thông báo xuất hiện chính xác.

## Requirements
### Functional
- Giả lập lập lịch và kích hoạt thông báo thành công.
- Nhận diện đúng điều kiện "tồn tại mục tiêu chưa hoàn thành".
- Đảm bảo thông báo hiển thị đầy đủ tiêu đề và nội dung Tiếng Việt chuẩn.

## Implementation Steps
1. [ ] Tích hợp một nút "Test Push Notification (5s)" tạm thời trên màn hình Profile hoặc Settings để kiểm tra hoạt động của plugin.
2. [ ] Thực hiện chạy thử nghiệm:
   - Bước 1: Tạo hồ sơ với ngày nhận lương bất kỳ. Tạo ít nhất 1 mục tiêu chưa hoàn thành.
   - Bước 2: Quan sát log xem lịch có được đăng ký thành công không.
   - Bước 3: Ấn nút test thông báo sau 5 giây -> khóa màn hình hoặc ẩn app xuống nền -> đợi thông báo xuất hiện.
   - Bước 4: Chuyển tất cả mục tiêu sang trạng thái hoàn thành -> kiểm tra log xem lịch đã được gỡ bỏ chưa.
3. [ ] Gỡ bỏ nút test tạm thời hoặc ẩn đi trong chế độ Dev trước khi đóng tính năng.

## Test Cases
- **TC-01:** Khởi tạo lần đầu tiên và cấp quyền thông báo thành công.
- **TC-02:** Có mục tiêu chưa hoàn thành + cập nhật ngày nhận lương -> Hệ thống đăng ký lịch nhắc nhở thành công.
- **TC-03:** Hoàn thành tất cả các mục tiêu -> Hệ thống tự động hủy lịch nhắc nhở.
- **TC-04:** Kích hoạt thử nghiệm thành công (hiển thị giao diện thông báo đẩy trên thiết bị).
