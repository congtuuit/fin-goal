import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';

part 'notification_service.g.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const int salaryReminderId = 1001;
  static const String channelId = 'salary_reminder_channel';
  static const String channelName = 'Nhắc nhở ngày nhận lương';
  static const String channelDescription = 'Kênh thông báo nhắc nhở kiểm kê tài chính vào ngày nhận lương';

  Future<void> initialize() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Android Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Initialization Settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 4. Initialize Plugin
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    debugPrint('NotificationService: Initialized successfully.');
  }

  /// Request permissions for Android (13+) and iOS
  Future<bool> requestPermissions() async {
    final iosPlatform = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlatform != null) {
      final granted = await iosPlatform.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('NotificationService: iOS permissions granted: $granted');
      return granted ?? false;
    }

    final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlatform != null) {
      final granted = await androidPlatform.requestNotificationsPermission();
      debugPrint('NotificationService: Android permissions granted: $granted');
      return granted ?? false;
    }

    return false;
  }

  /// Cancel any scheduled salary reminders
  Future<void> cancelSalaryReminder() async {
    await _localNotifications.cancel(id: salaryReminderId);
    debugPrint('NotificationService: Cancelled salary reminder.');
  }

  /// Schedule monthly salary reminder
  Future<void> scheduleSalaryReminder({
    required int salaryDay,
    required bool hasIncompleteGoals,
  }) async {
    // If no incomplete goals, cancel reminder to avoid spamming the user
    if (!hasIncompleteGoals) {
      await cancelSalaryReminder();
      return;
    }

    // Ensure salaryDay is valid (1 to 31)
    if (salaryDay < 1 || salaryDay > 31) {
      debugPrint('NotificationService ERROR: Invalid salaryDay ($salaryDay)');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    
    // Helper to clamp the salaryDay to the maximum number of days in the given month/year
    tz.TZDateTime getScheduledDateTime(int year, int month) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final clampedDay = salaryDay > daysInMonth ? daysInMonth : salaryDay;
      return tz.TZDateTime(
        tz.local,
        year,
        month,
        clampedDay,
        9, // 9:00 AM
        0,
      );
    }

    var scheduledDate = getScheduledDateTime(now.year, now.month);

    // If scheduled date is in the past, schedule for next month
    if (scheduledDate.isBefore(now)) {
      scheduledDate = getScheduledDateTime(now.year, now.month + 1);
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id: salaryReminderId,
      title: 'Hôm nay là ngày nhận lương! 💸',
      body: 'Đã đến lúc cập nhật và kiểm kê lại kế hoạch mục tiêu tài chính của bạn rồi. Vào app ngay nhé!',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Inexact to avoid Android 13+ permission crashes and Play Store policy checks
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    debugPrint(
        'NotificationService: Scheduled monthly salary reminder starting at $scheduledDate (Day $salaryDay of Month)');
  }

  /// Instantly schedule a test notification in 5 seconds
  Future<void> scheduleTestNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(seconds: 5));

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Kênh thông báo kiểm thử',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id: 9999,
      title: 'Thông báo kiểm thử ⚡',
      body: 'Đây là thông báo test sau 5 giây hoạt động thành công!',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Inexact to avoid exact alarm restrictions
    );
    debugPrint('NotificationService: Scheduled test notification in 5 seconds.');
  }
}

@riverpod
void salaryReminderScheduler(Ref ref) {
  final profileState = ref.watch(profileProvider);
  final goalsState = ref.watch(goalsProvider);

  if (profileState is ProfileLoaded && goalsState is GoalsLoaded) {
    final profile = profileState.profile;
    if (profile != null) {
      final hasIncompleteGoals = goalsState.goals.any((g) => g.status == 'active' && g.currentSavings < g.targetAmount);
      NotificationService.instance.scheduleSalaryReminder(
        salaryDay: profile.salaryDate,
        hasIncompleteGoals: hasIncompleteGoals,
      );
    } else {
      NotificationService.instance.cancelSalaryReminder();
    }
  }
}
