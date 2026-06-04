# Phase 03: UI Integration & SFX Triggers
Status: ⬜ Pending
Dependencies: Phase 02

## Objective
Gắn các hiệu ứng âm thanh vào hành động trong game và hiển thị nút cài đặt.

## Implementation Steps
1. [ ] Gắn `playDiceRoll()` vào nút đổ xúc xắc.
2. [ ] Gắn `playPayday()` vào action đi qua ô Payday.
3. [ ] Gắn `playCardFlip()` vào hành động rút thẻ Opportunity / Market.
4. [ ] Gắn `playSuccess()` vào hành động mua tài sản / trả nợ thành công (ví dụ trong FinancialReportDialog hoặc BuyAssetDialog).
5. [ ] Thêm nút Mute/Unmute vào Game Board (AppBar hoặc UI HUD).

## Files to Modify
- `mobile/lib/features/cashflow_game/presentation/pages/game_board_page.dart`
- Các widgets liên quan đến thẻ, xúc xắc, mua bán.
