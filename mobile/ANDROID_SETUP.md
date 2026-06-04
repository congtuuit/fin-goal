# Hướng dẫn cấu hình môi trường Android (Fin-Goal Mobile)

Tài liệu này ghi lại các cấu hình môi trường quan trọng và các lỗi (quirks) đã được xử lý để dự án có thể build thành công trên Android.

## 1. Yêu cầu môi trường chung
- **Flutter SDK**: Phiên bản mới nhất (khuyến nghị >= 3.29) hỗ trợ Built-in Kotlin.
- **Android SDK (compileSdk)**: **Bắt buộc phải là 36** (Android 15 / VanillaIceCream / Baklava).

## 2. Cách cài đặt Android SDK 36 (Quan trọng)
Do công cụ dòng lệnh `sdkmanager` (cmdline-tools v20.0 trở xuống) đang gặp lỗi không tương thích phiên bản XML (version 4) với kho lưu trữ của Google, việc cài đặt SDK ngầm qua terminal sẽ thất bại.
**Cách xử lý (Dành cho Developer mới):**
1. Mở phần mềm **Android Studio**.
2. Đi tới **Tools** > **SDK Manager**.
3. Tại tab **SDK Platforms**, tick chọn **Android API 36**.
4. Tại tab **SDK Tools**, tick cập nhật **Android SDK Command-line Tools (latest)**.
5. Bấm **Apply** > **OK** để tải và cài đặt.

## 3. Lỗi các thư viện bên thứ ba (Third-party Plugins)
Dự án sử dụng nhiều plugins yêu cầu Android SDK khá khắt khe:
- Nhóm `app_links`, `package_info_plus`, `share_plus`,... bắt buộc `compileSdk` >= 36 do phụ thuộc vào thư viện AndroidX nội bộ (ví dụ: `androidx.browser:browser:1.9.0`, `androidx.core:core-ktx:1.17.0`). Vì thế, dự án không thể hạ `compileSdk` xuống 34.
- Thư viện `audioplayers_android` có cấu hình cứng (hardcoded) là yêu cầu `compileSdk = 35`, dẫn đến lỗi thiếu file `android-35\android.jar` nếu máy dev chỉ cài mỗi API 36.

## 4. Cách Fix đã áp dụng (Global Override)
Thay vì bắt Developer phải tải hàng tá phiên bản SDK khác nhau (34, 35, 36) cho nặng máy, dự án đã sử dụng kỹ thuật **Kotlin Reflection** trong file `android/build.gradle.kts` để ép buộc tất cả các plugin sử dụng chung API 36.

Đoạn code can thiệp (trong `android/build.gradle.kts`):
```kotlin
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    // Trực tiếp sửa đổi bộ nhớ biến compileSdk của các plugin về 36
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (e: Exception) {}
            }
        }
    }
    project.evaluationDependsOn(":app")
}
```
Nhờ cơ chế này, developer chỉ cần duy nhất **Android SDK 36** là có thể build thành công toàn bộ dự án.

## 5. Lệnh chạy ứng dụng
Sau khi đã thiết lập đủ các yêu cầu trên, có thể chạy ứng dụng bình thường qua terminal:
```bash
flutter run
```
