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

  // ── AI Coach Proactive Notifications ─────────────────────────────────────

  static const int coachMilestoneId = 2001;
  static const int coachOffTrackId = 2002;
  static const int coachCheckinId = 2003;
  static const String coachChannelId = 'ai_coach_channel';
  static const String coachChannelName = 'AI Financial Coach';
  static const String coachChannelDescription =
      'Thông báo nhắc nhở và phân tích từ AI Financial Coach';

  static const _coachAndroidDetails = AndroidNotificationDetails(
    coachChannelId,
    coachChannelName,
    channelDescription: coachChannelDescription,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static const _coachNotificationDetails = NotificationDetails(
    android: _coachAndroidDetails,
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
  );

  /// Show a milestone celebration notification when user reaches a % milestone.
  ///
  /// Recommended thresholds: 25%, 50%, 75%, 90%, 100%.
  Future<void> showMilestoneCelebration({
    required String goalName,
    required String goalEmoji,
    required double progressPercent,
  }) async {
    final percent = progressPercent.toStringAsFixed(0);
    final title = '$goalEmoji Chúc mừng! Bạn đạt $percent% mục tiêu!';
    final body = progressPercent >= 100
        ? 'Bạn đã hoàn thành mục tiêu "$goalName"! Thật xuất sắc! 🎉'
        : 'Bạn đã tích lũy được $percent% cho mục tiêu "$goalName". Tiếp tục phát huy nhé!';

    await _localNotifications.show(
      id: coachMilestoneId,
      title: title,
      body: body,
      notificationDetails: _coachNotificationDetails,
      payload: 'milestone_$goalName',
    );
    debugPrint('NotificationService: Showed milestone notification ($percent%) for "$goalName".');
  }

  /// Show an off-track warning notification.
  /// Call when actual progress is significantly behind planned schedule.
  Future<void> showOffTrackWarning({
    required String goalName,
    required int delayMonths,
    required int suggestedMonthlySavingVnd,
  }) async {
    final extraAmount = _formatVnd(suggestedMonthlySavingVnd);
    await _localNotifications.show(
      id: coachOffTrackId,
      title: '⚠️ AI Coach: Mục tiêu "$goalName" có thể bị trễ',
      body: 'Nếu tiếp tục như hiện tại, mục tiêu có thể chậm $delayMonths tháng. '
          'Tăng thêm $extraAmount/tháng để về đích đúng hạn.',
      notificationDetails: _coachNotificationDetails,
      payload: 'off_track_$goalName',
    );
    debugPrint('NotificationService: Showed off-track warning for "$goalName" (delay: $delayMonths months).');
  }

  /// Schedule a monthly "Coach Checkin" notification to prompt user
  /// to review their goals and get fresh AI analysis.
  Future<void> scheduleMonthlyCoachCheckin({required int dayOfMonth}) async {
    final now = tz.TZDateTime.now(tz.local);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = dayOfMonth.clamp(1, daysInMonth);

    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, clampedDay, 10, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month + 1, clampedDay, 10, 0);
    }

    await _localNotifications.zonedSchedule(
      id: coachCheckinId,
      title: '🤖 AI Coach nhắc bạn kiểm tra mục tiêu tháng này',
      body: 'Bạn đã đạt được bao nhiêu % mục tiêu tháng này? Vào app để AI Coach phân tích và đưa lời khuyên nhé!',
      scheduledDate: scheduledDate,
      notificationDetails: _coachNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    debugPrint('NotificationService: Scheduled monthly coach checkin on day $clampedDay.');
  }

  /// Cancel all AI Coach notifications.
  Future<void> cancelCoachNotifications() async {
    await _localNotifications.cancel(id: coachMilestoneId);
    await _localNotifications.cancel(id: coachOffTrackId);
    await _localNotifications.cancel(id: coachCheckinId);
    debugPrint('NotificationService: Cancelled all coach notifications.');
  }

  String _formatVnd(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(0)} triệu';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return '$amount VNĐ';
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
