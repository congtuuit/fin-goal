# Phase 05: Testing & Refinement
Status: ⬜ Pending
Dependencies: Phase 04

## Objective
Kiểm thử tích hợp cho toàn bộ các luồng mới sửa và refactor code nếu cần.

## Tasks
- [x] Chạy ứng dụng trên môi trường Local.
- [x] Test luồng tạo thẻ -> ghim thẻ -> Đổi màu thẻ.
- [x] Test luồng Guest: Tạo mục tiêu offline -> Vào xem chi tiết (đảm bảo hiển thị dữ liệu đầy đủ, không lỗi).
- [x] Test luồng Đăng ký/Đăng nhập sau khi Guest đã tạo dữ liệu -> Vào DB Supabase check xem đã đẩy lên thành công hay chưa.
- [x] Test luồng Thanh toán (mô phỏng Payment Gateway trả về true) -> Check số lượng mục tiêu tối đa đã tăng và app tự điều hướng về Home.
- [x] Dọn dẹp các dòng `console.log`, fix lints.
