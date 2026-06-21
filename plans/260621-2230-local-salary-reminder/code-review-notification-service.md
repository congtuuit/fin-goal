# 🏥 ĐÁNH GIÁ SỨC KHỎE CODE: NotificationService

Dưới đây là báo cáo đánh giá chi tiết (Code Review) cho file [notification_service.dart](file:///d:/git/fin-goal/mobile/lib/core/services/notification_service.dart).

## 📊 Tổng quan
| Chỉ số | Đánh giá | Trạng thái |
|--------|---------|------------|
| Cấu trúc & Hướng đối tượng | Tốt, sử dụng mẫu Singleton hợp lý | 🟢 Tốt |
| Quản lý trạng thái (Riverpod) | Tích hợp reactive thông minh thông qua scheduler provider | 🟢 Tốt |
| Rủi ro Crash hệ thống | Cấu hình Exact Alarm trên Android 13+ có thể gây crash hoặc từ chối chính sách Google Play | ⚠️ Cần lưu ý |

---

## ✅ Điểm tốt
- **Tách biệt Logic (Clean Architecture)**: File chỉ tập trung vào cấu hình thông báo và lập lịch cục bộ, không bị lẫn lộn logic nghiệp vụ.
- **Lắng nghe Reactive**: Sử dụng `salaryReminderScheduler` để tự động lắng nghe cả `profileNotifierProvider` và `goalsNotifierProvider` giúp tự động hóa việc lên lịch và hủy lịch mà không cần gọi thủ công ở nhiều nơi.
- **Tiêu chuẩn hóa ID**: Các kênh thông báo (`channelId`) và ID thông báo (`salaryReminderId`) được khai báo dạng hằng số rõ ràng, tránh ghi đè nhầm lẫn.

---

## ⚠️ Cần cải thiện & Rủi ro

### 1. Rủi ro Crash & Vi phạm chính sách với Exact Alarms (Android 13+)
- **Vấn đề**: Hiện tại cấu hình đang dùng `AndroidScheduleMode.exactAllowWhileIdle`. Từ Android 13 trở lên, việc lập lịch Exact Alarm bắt buộc phải xin quyền đặc biệt hoặc cấp phép từ hệ thống. Nếu không được cấp quyền, phương thức lập lịch sẽ quăng ra một Exception gây crash ứng dụng. Ngoài ra, Google Play Store cấm lạm dụng Exact Alarm trừ các ứng dụng báo thức/lịch hẹn đặc thù.
- **Gợi ý**: Chuyển sang dùng `AndroidScheduleMode.inexactAllowWhileIdle`. Đối với nhắc nhở ngày nhận lương, việc thông báo lệch vài phút không ảnh hưởng đến trải nghiệm người dùng, giúp loại bỏ hoàn toàn việc xin quyền Exact Alarm phức tạp và tránh bị Google Play từ chối ứng dụng.

### 2. Timezone database import (`latest_all.dart`)
- **Vấn đề**: Sử dụng `import 'package:timezone/data/latest_all.dart'` sẽ import toàn bộ cơ sở dữ liệu múi giờ trên thế giới, điều này làm tăng dung lượng file build (APK/IPA) của ứng dụng một cách không cần thiết.
- **Gợi ý**: Chuyển sang sử dụng `import 'package:timezone/data/latest.dart'` để chỉ tải bộ dữ liệu múi giờ cơ bản/thu gọn, giúp tối ưu hóa dung lượng ứng dụng.

### 3. Xử lý trường hợp ngày nhận lương đặc biệt (Ngày 29, 30, 31)
- **Vấn đề**: Nếu người dùng nhận lương vào ngày 31, nhưng tháng tiếp theo chỉ có 30 ngày (hoặc tháng 2 có 28/29 ngày), đối tượng `tz.TZDateTime` khởi tạo với ngày nhận lương vượt quá số ngày của tháng đó sẽ tự động nhảy sang tháng kế tiếp nữa hoặc phát sinh lỗi.
- **Gợi ý**: Cần chuẩn hóa hoặc giới hạn ngày lập lịch nhắc nhở không vượt quá ngày cuối cùng của tháng đó.

---

## 🔧 Gợi ý thay đổi mã nguồn

```diff
-import 'package:timezone/data/latest_all.dart' as tz;
+import 'package:timezone/data/latest.dart' as tz;

...

-    await _localNotifications.zonedSchedule(
-      salaryReminderId,
-      'Hôm nay là ngày nhận lương! 💸',
-      'Đã đến lúc cập nhật và kiểm kê lại kế hoạch mục tiêu tài chính của bạn rồi. Vào app ngay nhé!',
-      scheduledDate,
-      notificationDetails,
-      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
-      uiLocalNotificationDateInterpretation:
-          UILocalNotificationDateInterpretation.absoluteTime,
-      matchDateTimeComponents: DateTimeComponents.dayOfMonth,
-    );
+    // Đảm bảo ngày nhận lương hợp lệ với tháng hiện tại
+    final daysInMonth = DateTime(scheduledDate.year, scheduledDate.month + 1, 0).day;
+    if (salaryDay > daysInMonth) {
+      scheduledDate = tz.TZDateTime(
+        tz.local,
+        scheduledDate.year,
+        scheduledDate.month,
+        daysInMonth,
+        9,
+        0,
+      );
+    }
+
+    await _localNotifications.zonedSchedule(
+      salaryReminderId,
+      'Hôm nay là ngày nhận lương! 💸',
+      'Đã đến lúc cập nhật và kiểm kê lại kế hoạch mục tiêu tài chính của bạn rồi. Vào app ngay nhé!',
+      scheduledDate,
+      notificationDetails,
+      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Đổi từ exact sang inexact để tránh crash Android 13+
+      uiLocalNotificationDateInterpretation:
+          UILocalNotificationDateInterpretation.absoluteTime,
+      matchDateTimeComponents: DateTimeComponents.dayOfMonth,
+    );
```
