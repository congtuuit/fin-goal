# Phase 02: Audio Service & Provider
Status: ⬜ Pending
Dependencies: Phase 01

## Objective
Xây dựng logic quản lý âm thanh và lưu trạng thái bật/tắt.

## Implementation Steps
1. [ ] Tạo `AudioService` (singleton hoặc dùng Riverpod Provider) quản lý `AudioPlayer`.
2. [ ] Thêm logic đọc/ghi biến `isSfxEnabled` từ `SharedPreferences`.
3. [ ] Tạo hàm `playDiceRoll()`, `playPayday()`, `playCardFlip()`, `playSuccess()`.
4. [ ] Tạo StateNotifier/Provider cho việc Bật/Tắt âm thanh trên UI.

## Files to Create
- `mobile/lib/core/services/audio_service.dart`
- `mobile/lib/features/cashflow_game/presentation/providers/audio_provider.dart`
