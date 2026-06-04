# Hướng Dẫn Thay Thế AdMob Lên Môi Trường Production

Để chạy quảng cáo thật (Production) và bắt đầu kiếm tiền từ ứng dụng, bạn cần thay thế các ID dùng thử (Test ID) hiện tại bằng các ID thật lấy từ tài khoản Google AdMob. 

Dưới đây là các bước chi tiết để chuyển sang môi trường Production:

## Bước 1: Đăng ký và tạo App trên AdMob
1. Truy cập [Google AdMob](https://admob.google.com/) và đăng nhập bằng tài khoản Google.
2. Tại bảng điều khiển, chọn **"Ứng dụng" (Apps) > "Thêm ứng dụng" (Add App)**.
3. Thêm lần lượt 2 ứng dụng: 1 cho **Android** và 1 cho **iOS** (Lưu ý: AdMob sẽ sinh ra 2 App ID khác nhau cho 2 nền tảng này).

## Bước 2: Thay thế App ID trong mã nguồn
Mỗi nền tảng sẽ có một **App ID** (định dạng `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` - chú ý có dấu `~`). Bạn cần copy ID này từ AdMob và thay thế vào code:

### 1. Cho Android
Mở file `android/app/src/main/AndroidManifest.xml` và thay ID thật vào thẻ `meta-data`:
```xml
<!-- Thay ca-app-pub-xxx~yyy bằng App ID thật của Android -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/> 
```

### 2. Cho iOS
Mở file `ios/Runner/Info.plist` và thay ID thật vào:
```xml
<!-- Thay ca-app-pub-xxx~yyy bằng App ID thật của iOS -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
```

## Bước 3: Tạo các đơn vị quảng cáo (Ad Units)
Trong mỗi ứng dụng (Android và iOS) trên bảng điều khiển AdMob, vào mục **"Đơn vị quảng cáo" (Ad units)** và tạo 3 loại sau:
1. **Banner** (Dành cho dải quảng cáo dưới màn hình).
2. **Rewarded** (Dành cho nút xem video nhận $1,000).
3. **Interstitial** (Dành cho lúc chơi lại game / check-in xong).

*Lưu ý: AdMob sẽ cấp cho bạn các Ad Unit ID có định dạng `ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz` (chú ý có dấu gạch chéo `/`).*

## Bước 4: Cập nhật Ad Unit ID vào AdService
Mở file `lib/core/services/ad_service.dart`. Tìm đến các hàm `get bannerAdUnitId`, `get interstitialAdUnitId`, và `get rewardedAdUnitId`. 

Thay các chuỗi ID bằng ID thật mà bạn vừa tạo:

```dart
// Ví dụ với Banner Ad:
static String get bannerAdUnitId {
  if (kIsWeb) return '';
  if (kDebugMode) {
    // ID Test của Google (Giữ nguyên để dev/test không bị dính gậy)
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
  }
  
  // ID PRODUCTION CỦA BẠN (Chỉ chạy khi build App release lên Store)
  if (Platform.isAndroid) return 'ca-app-pub-xxx/yyy_android'; 
  if (Platform.isIOS) return 'ca-app-pub-xxx/yyy_ios';
  return '';
}
```
*(Thực hiện tương tự cho Interstitial và Rewarded)*.

## ⚠️ Một Vài Lưu Ý Quan Trọng Cho Production
1. **Tuyệt đối không click vào quảng cáo của chính mình:** Nếu Google phát hiện bạn tự click, họ sẽ khóa tài khoản AdMob ngay lập tức. Đó là lý do code đang để `if (kDebugMode)` để khi chạy thử trên máy (Debug) nó vẫn hiển thị quảng cáo Test an toàn. Quảng cáo thật chỉ hiện khi build file Release đưa lên chợ ứng dụng.
2. **Setup thanh toán:** Bạn cần vào AdMob xác minh danh tính và cài đặt phương thức thanh toán thì quảng cáo mới bắt đầu phân phối (fill rate > 0).
