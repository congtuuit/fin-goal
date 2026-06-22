# 🏥 ĐÁNH GIÁ UI CODE: Scenario Dashboard

## 📊 Tổng quan
| Chỉ số | Kết quả | Đánh giá |
|--------|---------|----------|
| Kích thước | > 900 dòng | Cần tách file (Refactor) |
| UI Spacing | Nhiều Gap(xl), Gap(xxl) | Đang lãng phí không gian màn hình |
| Tách biệt Logic | Dialogs/Sheets nằm chung | Cần tách ra Widgets riêng biệt |

## ✅ Điểm tốt
- Đã chia các hàm builder như `_buildTimelineCard`, `_buildMacroControlPanel` giúp dễ quản lý hơn phần nào.
- Có xử lý đầy đủ các state: Loading, Error, Loaded.
- Áp dụng Riverpod và GoRouter tốt.

## ⚠️ Cần cải thiện
| Vấn đề | Ưu tiên | Gợi ý |
|--------|---------|-------|
| Spacing quá lớn | 🔴 Cao | Đổi `Gap(AppSizes.xxl)` và `Gap(AppSizes.xl)` thành `md` hoặc `lg` để giao diện gọn gàng hơn, nội dung hiển thị được nhiều hơn trên một màn hình. |
| File quá dài (>900 lines) | 🟡 Trung bình | Tách `_showEditDialog` và `_showSwitchGoalSheet` thành các components riêng ở thư mục `widgets/`. |
| Các Widgets Panel | 🟢 Thấp | Tách `TimelineCard`, `MacroControlPanel` thành các StatelessWidgets. |

## 🔧 Kế hoạch tối ưu tức thì
1. Cắt giảm các `Gap(AppSizes.xl)` xuống `Gap(AppSizes.lg)` hoặc `md`.
2. Cắt giảm các `Gap(AppSizes.xxl)` xuống `Gap(AppSizes.xl)`.
3. Giảm bớt padding trong các Container.
