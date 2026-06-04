# Phase 01: Setup & Core Logic
Status: ⬜ Pending

## Objective
Cập nhật mô hình dữ liệu để hỗ trợ trạng thái Fast Track.

## Implementation Steps
1. [ ] Thêm biến `isFastTrack` (bool), `fastTrackIncome`, `dreamId` vào `GameState`.
2. [ ] Tạo logic chuyển tiếp: Khi `passiveIncome >= totalExpenses`, kích hoạt hàm `enterFastTrack()`.
3. [ ] Hàm `enterFastTrack()`: Set tiền mặt = (Passive Income) * 100, xoá các khoản vay/tài sản Rat Race.
