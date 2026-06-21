# Plan: Local Salary Date Check-in Reminder
Created: 2026-06-21T22:30:00+07:00
Status: 🟡 In Progress

## Overview
Chào anh! Em là Hà, PM của dự án. 
Theo yêu cầu của anh, em đã lập kế hoạch để thêm tính năng **tự động nhắc nhở cục bộ (offline push notification)** vào đúng **ngày nhận lương** của người dùng (lấy từ cấu hình `FinancialProfile.salaryDate`). 
Thông báo này sẽ chỉ kích hoạt nếu tại thời điểm đó **vẫn còn mục tiêu chưa hoàn thành** (incomplete goals) để nhắc nhở họ kiểm kê lại kế hoạch tài chính hoặc check-in tháng.

Do là offline push notification (không cần server gieo định kỳ), chúng ta sẽ sử dụng gói `flutter_local_notifications` để lập lịch gửi định kỳ hàng tháng ngay trên thiết bị.

## Tech Stack
- Package đề xuất: `flutter_local_notifications` (để schedule local notification offline)
- Timezone handling: `timezone` package (bắt buộc đi kèm để schedule theo ngày giờ cụ thể)

## Phases

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 01 | Setup Notification Service | ⬜ Pending | 0% |
| 02 | Schedule Notification Logic | ⬜ Pending | 0% |
| 03 | Testing & Verification | ⬜ Pending | 0% |

## Quick Commands
- Start Phase 1: `/code phase-01`
- Check progress: `/next`
- Save context: `/save-brain`
