# Phase 03: Local Database (Isar Setup)

Status: ✅ Complete
Dependencies: [Phase 02: Offline Auth Module](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-02-offline-auth.md)

## Objective
Thiết lập cơ sở dữ liệu cục bộ Isar Database để lưu trữ thông tin Scenarios (Kịch bản) và Goals (Mục tiêu tài chính) ngoại tuyến thay vì gọi Supabase API.

## Implementation Steps
1. [x] Tạo file mô hình dữ liệu Isar (Isar Collection) cho `Scenario` (id, title, targetAmount, description, v.v.).
2. [x] Tạo file mô hình dữ liệu Isar (Isar Collection) cho `Goal` (id, name, type, description, targetDate, v.v.).
3. [x] Tạo file `local_goal_repository.dart` và `local_scenario_repository.dart` kế thừa từ các Interface tương ứng để thực hiện thao tác đọc/ghi vào Isar DB.
4. [x] Đăng ký các Repository này vào Dependency Injection làm mặc định.
5. [x] Cập nhật UI hiển thị:
   - Dashboard: Load danh sách kịch bản hiện có của người dùng từ `ScenarioRepository`.
   - GoalSelection: Cho phép tạo mục tiêu mới và lưu qua `GoalRepository`.
   - MonthlyCheckin: Cho phép cập nhật tiến độ lưu lại vào Isar DB.

## Files to Create/Modify
- `mobile/lib/core/database/models/scenario_model.dart` - [NEW]
- `mobile/lib/core/database/models/goal_model.dart` - [NEW]
- `mobile/lib/core/repositories/local_goal_repository.dart` - [NEW]
- `mobile/lib/core/repositories/local_scenario_repository.dart` - [NEW]
- UI pages liên quan (Dashboard, GoalSelection, MonthlyCheckin) - [MODIFY]

## Test Criteria
- [ ] Dữ liệu thêm mới mục tiêu/kịch bản hiển thị lập tức lên UI Dashboard.
- [ ] Dữ liệu được lưu trữ an toàn khi tắt app hoặc reload app.
- [ ] Các chức năng CRUD chạy ngoại tuyến hoàn toàn mượt mà.

---
Next Phase: [Phase 04: AI Client-Side Settings](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-04-ai-client-side.md)
