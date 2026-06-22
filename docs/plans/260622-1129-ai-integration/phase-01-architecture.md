# Phase 01: Setup & Architecture
Status: ⬜ Pending

## Objective
Tạo các abstract classes, interfaces và cấu hình Riverpod Providers để chuẩn bị cho việc tích hợp AI. Điều này đảm bảo code tuân thủ nguyên tắc SOLID, đặc biệt là Dependency Inversion.

## Implementation Steps
1. [ ] Thiết kế thư mục tính năng: `lib/features/ai_assistant/`
2. [ ] Thiết kế `AIAssistantService` abstract interface.
3. [ ] Khai báo provider rỗng `aiAssistantServiceProvider` trong Riverpod.
4. [ ] Tạo data class (DTO) `GoalAdvice` chứa kết quả trả về từ AI.

## Files to Create/Modify
- `lib/features/ai_assistant/domain/services/ai_assistant_service.dart`
- `lib/features/ai_assistant/providers/ai_providers.dart`
- `lib/features/ai_assistant/domain/models/goal_advice.dart`

---
Next Phase: phase-02-service-implementation.md
