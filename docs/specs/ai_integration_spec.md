# Phân Tích Kỹ Thuật: Tích hợp AI Trợ Lý Tài Chính (Fin-Goal AI)

## 1. Executive Summary
Tích hợp tính năng Trợ lý AI vào Fin-Goal để cung cấp nhận xét tiến độ, phân tích kịch bản tự động, và chia nhỏ mục tiêu thông minh. 
Giai đoạn đầu sẽ gọi trực tiếp AI API (vd: Google Gemini) từ thiết bị di động (sử dụng API key do người dùng cấu hình trong màn hình Profile). Sau này sẽ migrate để gọi qua backend.

## 2. User Stories
- Là người dùng, tôi muốn nhận được lời khuyên/nhận xét tiến độ bằng ngôn ngữ tự nhiên thay vì chỉ các con số, để tôi có động lực tiết kiệm hơn.
- Là người dùng, tôi muốn tự động sinh ra kịch bản lạc quan/bi quan mà không cần tự nhập lãi suất và lạm phát.
- Là người dùng, tôi muốn điền API Key AI vào Profile để ứng dụng có thể sử dụng AI trực tiếp từ điện thoại.

## 3. Logic Flowchart
- Màn hình Profile -> Cấu hình API Key -> Lưu vào LocalStorage/SecureStorage.
- Dashboard -> Lấy dữ liệu mục tiêu hiện tại -> Gửi prompt tới `AIAssistantService` -> Gọi API -> Trả về kết quả hiển thị trên "AI Coach Card".

## 4. API Contract / Interface
```dart
abstract class AIAssistantService {
  Future<String> getGoalAdvice(Goal goal, Progress currentProgress);
  Future<List<Scenario>> generateScenarios(Goal goal);
}
```

## 5. UI Components
- **AI Config Section:** Thêm vào Profile/Settings Page để nhập API Key.
- **AI Coach Card:** Widget hiển thị trên Dashboard hoặc Goal Detail Page, có icon lấp lánh (sparkles) và text trả về từ AI. Shimmer effect khi đang loading.

## 6. Tech Stack
- Frontend: Flutter, Riverpod cho State Management.
- AI Integration: Gói `google_generative_ai` (cho Gemini) hoặc gọi REST API trực tiếp.

## 7. Hidden Requirements
- Cần xử lý lỗi khi API Key bị sai, hết quota, hoặc không có mạng (Fall-back về nhận xét mặc định).
- Tránh gọi AI liên tục mỗi lần rebuild UI (cần cache kết quả AI theo phiên hoặc lưu vào local database).
