# Phase 04: Profile Page Guest Mode
Status: ⬜ Pending
Dependencies: Phase 03

## Objective
Cập nhật màn hình Profile để hiển thị theo trạng thái Authenticated hoặc Guest.

## Requirements
### Functional
- [ ] Nếu là Guest: Hiển thị tên Guest, Avatar mặc định, lời mời "Lưu lại tiến trình của bạn", và nút Đăng nhập Google to.
- [ ] Nếu là Authenticated (đã login Google): Hiển thị Tên thật từ Google, Email, nút Đăng xuất.

## Implementation Steps
1. [ ] Trong `ProfilePage`, watch trạng thái `isAuthenticated`.
2. [ ] Dùng `if/else` trên UI để render giao diện tương ứng (GuestView vs AuthenticatedView).

## Files to Modify
- `mobile/lib/features/profile/presentation/pages/profile_page.dart`

---
Next Phase: None
