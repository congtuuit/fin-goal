# Phase 03: UI Integration
Status: ⬜ Pending
Dependencies: phase-02-service-implementation.md

## Objective
Hiển thị lời khuyên của AI trên giao diện người dùng và xử lý cache.

## Implementation Steps
1. [ ] Kiểm tra và đảm bảo UI nhập API Key trong Profile/Settings đang hoạt động và lưu đúng.
2. [ ] Tạo widget `AICoachCard` có hiệu ứng shimmer lúc loading.
3. [ ] Nhúng `AICoachCard` vào Dashboard hoặc màn hình Chi tiết Mục tiêu.
4. [ ] Thêm logic caching: Tránh gọi lại AI mỗi khi người dùng vuốt/scroll (chỉ gọi 1 lần mỗi phiên hoặc có nút Refresh thủ công).

## Files to Create/Modify
- `lib/features/ai_assistant/presentation/widgets/ai_coach_card.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` (hoặc page tương đương)
