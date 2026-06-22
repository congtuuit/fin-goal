━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 HANDOVER DOCUMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Đang làm: Tối ưu UI & Đồng bộ hóa Google Sign-In & Sửa lỗi Auth Session cho Guest
🔢 Đến bước: Hoàn thành toàn bộ Phase tối ưu và fix lỗi. Toàn bộ code đã clean, compile thành công.

✅ ĐÃ XONG:
   - Phase 1: Tạo và tối ưu Draggable Floating AI Button (`46.0` size) có cơ chế snap-to-edge mượt mà.
   - Phase 2: Thiết kế slide-up Bottom Sheet dính biên (chỉ bo góc trên) hiển thị AI Coach Card.
   - Phase 3: Xây dựng widget dùng chung `GoogleSignInButton` chuẩn hóa theo Google Design Guidelines. Đồng bộ hóa 3 màn hình: Login Page, Login Bottom Sheet và Settings Page.
   - Phase 4: Sửa lỗi mất session Guest khi khởi động lại ứng dụng. Lưu trữ thông tin đăng nhập (`logged_in_user`) vào local storage (SharedPreferences) để khôi phục phiên tức thời.
   - Phase 5: Soạn thảo kế hoạch nâng cấp cơ chế đồng bộ hóa dữ liệu (Bulk Insert, RPC Database Transaction, SQLite DB, Conflict Resolution) lưu tại `docs/plans/data_sync_upgrade_plan.md`.

🔧 QUYẾT ĐỊNH QUAN TRỌNG:
   - Dùng Bottom Sheet dính biên thay vì Dialog hoặc card nổi để mang lại cảm giác mượt mà và tận dụng tốt không gian.
   - Sử dụng local storage (SharedPreferences) để lưu thông tin AppUser thay vì chỉ phụ thuộc vào Supabase session bất đồng bộ để tăng tốc độ mở app.
   - Tạo widget dùng chung GoogleSignInButton để dọn dẹp các đoạn mã SVG trùng lặp và tuân thủ Google Branding Policy.

⚠️ LƯU Ý CHO SESSION SAU:
   - Ứng dụng đã hoàn toàn sạch lỗi compile. Có thể tiến hành chạy thử thực tế ngay trên Emulator.
   - Đã lưu kế hoạch nâng cấp đồng bộ hóa dữ liệu ngoại tuyến lên Supabase để tham khảo cho các buổi phát triển kế tiếp.

📁 FILES QUAN TRỌNG:
   - mobile/lib/features/coach/presentation/widgets/draggable_ai_coach_button.dart
   - mobile/lib/features/coach/presentation/widgets/ai_coach_card.dart
   - mobile/lib/features/auth/presentation/widgets/google_sign_in_button.dart
   - mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
   - docs/plans/data_sync_upgrade_plan.md
   - .brain/brain.json
   - .brain/session.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Đã lưu! Để tiếp tục trong phiên tiếp theo: Gõ /recap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
