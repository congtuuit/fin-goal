# Tài liệu Tổng quan Hệ thống (System Overview)

Ngày cập nhật: 03/06/2026
Dự án: **fin-goal (Financial Simulator App)**

---

## 1. Công nghệ & Kiến trúc (Tech Stack & Architecture)

Dự án áp dụng kiến trúc **Clean Architecture** kết hợp với cấu trúc thư mục **Feature-First** (tất cả các thành phần liên quan đến một tính năng được gom vào một thư mục). 

- **Ngôn ngữ & Framework**: Dart, Flutter (>= 3.19.0, tương thích 3.29.x)
- **Quản lý State (State Management)**: Riverpod 3.0 (`flutter_riverpod` ^3.3.1) kết hợp Code Generation (`riverpod_annotation`).
- **Dependency Injection**: `get_it` kết hợp với `injectable` (tạo code tự động).
- **Điều hướng (Routing)**: `go_router` (khai báo dạng declarative).
- **Giao diện & UI**: 
  - Giao diện tùy chỉnh (Custom design) không phụ thuộc sâu vào Material.
  - Sử dụng `flutter_animate` cho micro-animations.
  - Hỗ trợ ảnh vector (`flutter_svg`) và Lottie animations.
- **Backend & Database (BaaS)**: **Supabase** (Xử lý toàn bộ logic Xác thực, Database và Storage).
- **Phân tích (Analytics)**: `posthog_flutter`.
- **Thanh toán (Payments)**: `purchases_flutter` (RevenueCat) cho Subscriptions.
- **Thông báo (Push Notifications)**: `firebase_core` & `firebase_messaging`.
- **Cache / Local Storage**: `shared_preferences`.

---

## 2. Các Tính năng Hiện tại (Features)

Danh sách các tính năng được tổ chức theo từng module trong thư mục `lib/features/`:

### 🔐 1. Authentication (Tính năng Xác thực)
- **Luồng Logic (Có gọi API thật)**: 
  - Hoạt động dựa trên **Supabase Auth API**.
  - `AuthRepositoryImpl` (nằm trong `lib/features/auth/data/repositories/`) sẽ thực hiện các lời gọi API thực tế đến Supabase như: `signInWithPassword`, `signUp`, và `signInWithOAuth` (Google).
  - Lỗi trả về từ Supabase (bằng tiếng Anh) sẽ được dịch tự động sang tiếng Việt thân thiện với người dùng (ví dụ: "Email hoặc mật khẩu không đúng").
- **Màn hình**: Splash (Kiểm tra session hiện tại) -> Login -> Register.

### 🧭 2. Onboarding (Hướng dẫn người dùng mới)
- Thu thập thông tin ban đầu của người dùng trước khi cho phép vào màn hình chính.
- State được theo dõi thông qua biến `hasCompletedOnboarding`.

### 🎯 3. Goals (Mục tiêu tài chính)
- Người dùng có thể chọn hoặc thiết lập mục tiêu tài chính của riêng mình (Mua nhà, Mua xe, Nghỉ hưu, v.v.).
- Màn hình chính: `GoalSelectionPage`.

### 📊 4. Scenarios (Kịch bản & Mô phỏng)
- Đây là cốt lõi của ứng dụng (Financial Simulator).
- **Scenario Dashboard (`scenario_dashboard_page.dart`)**: Màn hình tổng quan về kịch bản tài chính.
- **Monthly Check-in (`monthly_checkin_page.dart`)**: Chức năng kiểm tra/cập nhật tiến độ hàng tháng. Hệ thống cho phép người dùng nhập chi tiêu/thu nhập để đánh giá tiến độ.
- **What-If Analysis (`what_if_page.dart`)**: Công cụ mô phỏng dự báo tương lai. Gửi truy vấn và nhận lại lời giải thích/dự báo từ AI (`aiExplanationProvider`).

### 💎 5. Premium / Paywall (Gói trả phí)
- Được quản lý bởi RevenueCat (`purchases_flutter`).
- Khóa một số chức năng nâng cao (như mô phỏng "What-If" chuyên sâu) và yêu cầu người dùng nâng cấp.
- Màn hình: `PaywallPage`.

### 👤 6. Profile (Hồ sơ người dùng)
- Quản lý thông tin cá nhân và thiết lập tài khoản.

---

## 3. Luồng Điều hướng Chính (Routing Flow)

Luồng điều hướng được cấu hình tại `lib/app/router/app_router.dart`:

1. **Khởi động**: Luôn bắt đầu tại `SplashPage` (`/`).
2. **Kiểm tra Session**:
   - Nếu *Chưa đăng nhập* -> Bị điều hướng ép buộc về `LoginPage` (`/login`).
   - Nếu *Đã đăng nhập* nhưng *Chưa hoàn thành Onboarding* -> Chuyển sang `OnboardingPage` (`/onboarding`).
   - Nếu *Đã đăng nhập* và *Đã làm xong Onboarding* -> Chuyển vào màn hình chính `ScenarioDashboardPage` (`/home`).
3. **Phân nhánh từ Home**:
   - `/home/goal-selection`
   - `/home/what-if`
   - `/home/monthly-checkin`
   - `/home/paywall`

---

## 4. Thông tin Cấu hình (Environment & Build)

- **Android Gradle Plugin (AGP)**: Đang chạy ở phiên bản **9.0.1** (để tương thích với thư viện lõi `androidx.browser` 1.9.0 của Firebase).
- **Biến môi trường**: Yêu cầu khai báo `.env` cho các key của Supabase, RevenueCat và PostHog.
- **Xử lý ngoại lệ Build**: Dự án đang tạm thời vô hiệu hóa Kotlin Built-in (`android.builtInKotlin=false`) để vượt qua rào cản tương thích của các thư viện cũ (như `app_links`). Thư viện `sentry_flutter` đang tạm thời bị tháo gỡ khỏi `main.dart` do xung đột JNI.

> Tài liệu này được tạo tự động bởi hệ thống AWF (Antigravity). Lần sau bạn có thể đọc lại tài liệu này để nắm bắt toàn bộ ngữ cảnh dự án mà không cần đọc code.
