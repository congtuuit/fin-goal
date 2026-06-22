# Phase 04: Data Sync Logic
Status: ⬜ Pending
Dependencies: Phase 03

## Objective
Tự động đồng bộ mục tiêu từ máy khách (Guest) lên tài khoản trên Server ngay khi người dùng đăng ký hoặc đăng nhập.

## Requirements
### Functional
- [x] Phân tích Data Sync Repository hiện tại (nếu có).
- [x] Đảm bảo logic đọc toàn bộ local JSON từ SharedPreferences và đẩy (upsert/insert) vào Supabase DB được trơn tru.
- [x] Cập nhật hàm `syncOfflineDataToServer` (hoặc tương tự) gọi vào lúc `AuthSuccess` (User login/register thành công).

## Implementation Steps
1. [x] Viết hàm `syncOfflineDataToServer()`.
2. [x] Gọi hàm này ở cuối luồng Authentication.
3. [ ] Chờ kết quả trả về, update state chung của app.

## Test Criteria
- [ ] Khách đang ở ngoài, tạo 2 mục tiêu A và B.
- [ ] Đăng nhập vào tài khoản.
- [ ] Kiểm tra DB thấy có 2 mục tiêu A và B. Đăng nhập qua thiết bị khác cũng thấy A và B.

---
Next Phase: [Phase 05](phase-05-testing.md)
