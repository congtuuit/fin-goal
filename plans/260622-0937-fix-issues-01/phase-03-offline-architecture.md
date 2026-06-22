# Phase 03: Offline Architecture (Guest Mode)
Status: ⬜ Pending
Dependencies: Phase 02

## Objective
Làm lại cấu trúc dữ liệu Local cho Guest Mode, đảm bảo màn hình chi tiết mục tiêu có thể đọc dữ liệu offline mà không bị lỗi trống.

## Requirements
### Functional
- [x] Refactor cấu trúc Storage Local (Guest Mode):
  - [x] Bảng `financial_profiles`
  - [x] Bảng `goals`
  - [x] Bảng `monthly_records`
  - [x] Bảng `scenario_queries`
- [x] Đảm bảo khi thao tác thêm/sửa/xoá Local sẽ có cấu trúc JSON mapping y hệt khi insert Supabase (Dùng chung Data Model).
- [x] Sửa lỗi xem chi tiết Goal bị trống ở chế độ Guest.

## Implementation Steps
1. [x] Viết/cập nhật Local Service (chuyên CRUD cho mục tiêu trên máy khách).
2. [x] Khi tạo mới mục tiêu: Generate một mock ID ở local.
3. [x] Sửa component màn hình Chi tiết Mục tiêu: Thêm fallback đọc data từ Local Service nếu user chưa đăng nhập.

## Test Criteria
- [x] Mở app (không đăng nhập) -> Tạo mục tiêu -> Bấm vào thẻ -> Xem chi tiết được bình thường (không trắng trang).

---
Next Phase: [Phase 04](phase-04-sync-data.md)
