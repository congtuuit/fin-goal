# Phase 04: AI Client-Side Settings & Direct API Integration

Status: ✅ Complete
Dependencies: [Phase 03: Local Database (Isar Setup)](file:///d:/git/fin-goal/plans/260603-1850-mvp-offline/phase-03-local-database.md)

## Objective
Tích hợp cấu hình cài đặt AI (nhập API Key, chọn Provider và Model lưu cục bộ trên máy) và hiện thực hóa kết nối trực tiếp client-side để chạy tính năng phân tích kịch bản tài chính "What-If" qua AI.

## Implementation Steps
1. [x] Tạo trang `settings_page.dart` (hoặc tích hợp vào Profile) cho phép cấu hình AI:
   - Chọn Provider: Google Gemini hoặc OpenAI.
   - Trường nhập API Key (sử dụng mật khẩu/che ký tự).
   - Chọn Model (ví dụ: gemini-2.5-flash, gpt-4o-mini).
   - Lưu trữ các cấu hình này cục bộ.
2. [x] Tạo file `direct_client_ai_service.dart` implement `AiService`.
   - Lấy thông tin cấu hình key/provider/model từ bộ nhớ local.
   - Sử dụng HTTP Client để tạo API Request trực tiếp từ client-side lên máy chủ của OpenAI/Google.
3. [x] Đăng ký `DirectClientAiService` làm `AiService` mặc định qua DI.
4. [x] Cập nhật màn hình `what_if_page.dart`:
   - Lấy câu hỏi/dữ liệu kịch bản của người dùng gửi cho `AiService`.
   - Hiển thị phản hồi phân tích của AI thật sự trên giao diện.
   - Nếu chưa nhập API Key, hiển thị thông báo hướng dẫn người dùng vào trang Settings để cài đặt Key trước.

## Files to Create/Modify
- `mobile/lib/features/profile/presentation/pages/settings_page.dart` - [NEW]
- `mobile/lib/core/services/direct_client_ai_service.dart` - [NEW]
- `mobile/lib/features/scenarios/presentation/pages/what_if_page.dart` - [MODIFY]

## Test Criteria
- [ ] Chưa cấu hình Key: Màn hình What-If hiển thị thông báo "Vui lòng cấu hình API Key trong phần Cài đặt".
- [ ] Nhập API Key hợp lệ và đặt câu hỏi -> AI trả về phân tích kịch bản tài chính chính xác sau vài giây.
- [ ] API Key được lưu trữ mã hóa/bảo mật, không bị lộ ra log hay git.
