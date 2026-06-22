# Phase 02: Service Implementation
Status: ⬜ Pending
Dependencies: phase-01-architecture.md

## Objective
Triển khai service cụ thể để gọi AI từ thiết bị, đọc API Key từ Settings.

## Implementation Steps
1. [ ] Cài đặt package cần thiết (vd: `google_generative_ai`) vào pubspec.yaml.
2. [ ] Viết `LocalGeminiAIService` implements `AIAssistantService`.
3. [ ] Cấu hình logic lấy API key hiện tại từ hệ thống Settings/Profile của app (xử lý lỗi khi key rỗng).
4. [ ] Tạo prompt template: Viết đoạn text hướng dẫn AI đóng vai trò là chuyên gia tài chính.
5. [ ] Cập nhật provider để bind implementation này.

## Files to Create/Modify
- `pubspec.yaml`
- `lib/features/ai_assistant/data/services/local_gemini_ai_service.dart`
- `lib/features/ai_assistant/providers/ai_providers.dart`

---
Next Phase: phase-03-ui-integration.md
