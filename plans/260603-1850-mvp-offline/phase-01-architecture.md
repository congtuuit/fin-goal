# Phase 01: Design Architecture & Interfaces

Status: ✅ Complete
Dependencies: None

## Objective
Thiết lập các lớp Interfaces cho phần Auth, Database (Repositories) và AI Services nhằm đảm bảo tính độc lập giữa giao diện người dùng và logic xử lý dữ liệu. Điều này giúp dễ dàng chuyển đổi hoặc cấu hình chế độ Offline/Online thông qua Dependency Injection.

## Implementation Steps
1. [x] Tạo file Interface `auth_service.dart` định nghĩa các hàm: `currentUser`, `loginWithName(String name)`, `logout()`.
2. [x] Tạo file Interface `ai_service.dart` định nghĩa hàm `generateScenarioSimulation(String prompt)`.
3. [x] Tạo file Interface `goal_repository.dart` định nghĩa các hàm CRUD cho mục tiêu tài chính (`getGoals`, `saveGoal`, `deleteGoal`, v.v`).
4. [x] Tạo file Interface `scenario_repository.dart` định nghĩa các hàm CRUD cho kịch bản mô phỏng.

## Files to Create/Modify
- `mobile/lib/core/services/auth_service.dart` - [NEW]
- `mobile/lib/core/services/ai_service.dart` - [NEW]
- `mobile/lib/core/repositories/goal_repository.dart` - [NEW]
- `mobile/lib/core/repositories/scenario_repository.dart` - [NEW]

## Test Criteria
- [ ] Các Interface được định nghĩa rõ ràng, không có compile error.
- [ ] Sẵn sàng để các lớp Local Service implement trong các Phase tiếp theo.

---
Next Phase: [Phase 02: Offline Auth Module](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-02-offline-auth.md)
