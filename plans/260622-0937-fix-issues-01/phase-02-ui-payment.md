# Phase 02: Fix UI Home & Payment Flow
Status: ⬜ Pending
Dependencies: Phase 01

## Objective
Sửa lỗi chọn thẻ để ghim ở màn hình Home và tự động cộng hạn mức/điều hướng sau khi thanh toán.

## Requirements
### Functional
- [x] Sửa `goals_list_page.dart`: Cho phép bất kỳ item card nào trong danh sách có thể đánh dấu `*` để ghim.
- [x] Sửa `goals_list_page.dart`: Chuyển logic đổi màu (highlight) từ việc check `isPrimary` sang check `isPinned`.
- [x] Kiểm tra màn hình Payment: Đảm bảo sau khi thanh toán mua thêm slot thành công thì:
  - [x] Gọi cập nhật profile với `purchasedGoalSlots`.
  - [x] Điều hướng (navigate) về màn hình Home. sau khi mua thành công.

## Implementation Steps
1. [ ] Mở file Component màn hình Home. Cập nhật state hoặc dữ liệu truyền vào của thẻ để nhận diện cờ `isPinned`.
2. [ ] Thêm action gắn cờ `isPinned` cho thẻ được chọn và hủy cờ của thẻ khác. Cập nhật class/CSS highlight.
3. [ ] Mở file xử lý thanh toán (Payment flow/callback). Thêm lệnh cộng hạn mức cho User.
4. [ ] Thêm lệnh `navigate('/home')` hoặc tương đương sau khi xử lý thành công.

## Test Criteria
- [ ] Pin thẻ thứ 2 -> Thẻ 2 sáng, thẻ 1 tắt highlight.
- [ ] Hoàn thành thanh toán -> Hạn mức +1, điều hướng thẳng về Home.

---
Next Phase: [Phase 03](phase-03-offline-architecture.md)
