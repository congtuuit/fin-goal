# Phase 03: Login Bottom Sheet
Status: ⬜ Pending
Dependencies: Phase 02

## Objective
Xây dựng một Bottom Sheet dùng chung, yêu cầu người dùng đăng nhập bằng Google khi muốn mua Premium.

## Requirements
### Functional
- [ ] Thiết kế UI cho `LoginBottomSheet` thân thiện, có nút Đăng nhập Google.
- [ ] Gọi Bottom Sheet khi người dùng bấm "Mua Premium" ở bất kỳ trang nào (ví dụ: `MonthlyCheckinPage` hoặc `GoalsListPage`).

## Implementation Steps
1. [ ] Tạo file `mobile/lib/features/auth/presentation/widgets/login_bottom_sheet.dart`.
2. [ ] Thêm logic gọi hàm `showModalBottomSheet` với widget trên tại các màn hình bắt mua tính năng.
3. [ ] Xử lý logic đóng sheet sau khi đăng nhập thành công.

## Files to Create/Modify
- `mobile/lib/features/auth/presentation/widgets/login_bottom_sheet.dart` [NEW]
- Các màn hình liên quan tới Premium (vd: `paywall_page.dart` hoặc nơi gắn nút).

---
Next Phase: Phase 04 Profile
