# 🔐 Hướng dẫn Cấu hình Biến Môi trường (Environment Setup)

Tài liệu này hướng dẫn chi tiết cách lấy thông tin để điền vào file `.env` cho dự án **fin-goal**.

---

## 1. Supabase (Database & Authentication)

Hệ thống hỗ trợ 2 môi trường: **Local Development** (chạy cục bộ dưới máy qua Docker) và **Cloud** (trên máy chủ Supabase).

### A. Chạy cục bộ (Local Development)
Nếu chạy local, bạn sử dụng các thông số mặc định có sẵn trong file `.env.example`:
* `SUPABASE_URL=http://localhost:54321`
* `SUPABASE_ANON_KEY=your-local-anon-key` (Được sinh ra sau khi chạy lệnh `supabase start`).

### B. Chạy trên Cloud (Supabase.com)
1. Truy cập [Supabase Console](https://supabase.com/) và đăng nhập.
2. Tạo một Project mới hoặc chọn Project hiện có.
3. Ở thanh menu bên trái, chọn **Project Settings** (biểu tượng bánh răng) ⚙️ -> Chọn mục **API**.
4. Lấy thông tin tại phần **Project API keys**:
   * **URL**: Sao chép địa chỉ tại ô **Project URL** -> Điền vào `SUPABASE_URL`.
   * **Anon Key**: Sao chép chuỗi ký tự tại ô **`anon` `public`** -> Điền vào `SUPABASE_ANON_KEY`.

---

## 2. Sentry (Error & Crash Tracking)

Sentry dùng để bắt lỗi ứng dụng khi chạy Production và báo cáo lỗi thời gian thực.

1. Truy cập [Sentry.io](https://sentry.io/) và đăng nhập.
2. Chọn **Create Project** -> Chọn nền tảng là **Flutter** -> Đặt tên dự án và bấm tạo.
3. Sau khi dự án được tạo, truy cập vào **Project Settings** (bánh răng) -> Chọn dự án vừa tạo.
4. Chọn mục **Client Keys (DSN)** ở menu bên trái.
5. Sao chép chuỗi URL hiển thị ở ô **DSN** (có dạng `https://<key>@<host>/<project_id>`) -> Điền vào `SENTRY_DSN`.

*Lưu ý: Nếu chưa muốn cấu hình bắt lỗi trong quá trình dev, bạn có thể để trống trường này.*

---

## 3. RevenueCat (In-app Purchases / Premium)

RevenueCat quản lý gói cước thanh toán trong ứng dụng cho iOS (App Store) và Android (Google Play).

1. Đăng nhập vào [RevenueCat Dashboard](https://app.revenuecat.com/).
2. Chọn dự án của bạn (hoặc tạo dự án mới).
3. Vào **Project Settings** -> Chọn **API Keys**.
4. Tạo API keys cho từng nền tảng:
   * **iOS (App Store)**: Tạo một public key mới -> Điền vào `REVENUECAT_APPLE_KEY`.
   * **Android (Google Play)**: Tạo một public key mới -> Điền vào `REVENUECAT_GOOGLE_KEY`.

*Lưu ý: Ở chế độ chạy local dev hoặc test UI, bạn có thể để trống cho đến khi cần tích hợp thật.*

---

## 4. PostHog (Product Analytics)

PostHog dùng để ghi nhận hành vi sử dụng và quay video màn hình test (Session Recording).

1. Truy cập [PostHog.com](https://posthog.com/) và đăng ký/đăng nhập.
2. Chọn hoặc tạo một Project mới.
3. Vào mục **Project Settings** ở góc trái phía dưới.
4. Tại tab **API Keys**:
   * Sao chép chuỗi **Project API Key** (thường bắt đầu bằng `phc_...`) -> Điền vào `POSTHOG_API_KEY`.
   * Cấu hình **PostHog Host**:
     * Nếu bạn chọn server ở Mỹ (US): Sử dụng `https://app.posthog.com` (mặc định).
     * Nếu bạn chọn server ở Châu Âu (EU): Thay đổi thành `https://eu.posthog.com`.
