
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/movie.dart';
import '../router/app_router.dart';
import '../data/database_helper.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- Định nghĩa các kênh thông báo ---
  static const AndroidNotificationChannel upcomingMovieChannel =
      AndroidNotificationChannel(
    'upcoming_movie_channel', // id
    'Upcoming Movies', // title
    description: 'Notifications for new upcoming movies.', // description
    importance: Importance.max,
  );

  static const AndroidNotificationChannel scheduledChannel =
      AndroidNotificationChannel(
    'scheduled_channel', // id
    'Scheduled Reminders', // title
    description: 'Notifications scheduled for a specific time.', // description
    importance: Importance.high,
  );

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Sử dụng app icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true, // Yêu cầu quyền hiển thị badge
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // --- Đăng ký các kênh với hệ thống Android ---
    if (!kIsWeb) {
      final plugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(upcomingMovieChannel);
      await plugin?.createNotificationChannel(scheduledChannel);
    }
  }

  // Hàm xử lý khi người dùng nhấn vào thông báo
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    // Xóa badge khi người dùng nhấn vào thông báo
    await clearAppBadge();
    if (payload != null) {
      AppRouter.router.go('/movie/$payload');
    }
  }

  Future<void> showUpcomingMovieNotification(Movie movie) async {
    // Tăng số lượng badge trước khi hiển thị thông báo
    await _incrementBadgeCount();

    // Lưu thông báo vào DB
    await _dbHelper.insertAppNotification({
      'movie_id': movie.id,
      'title': 'Sắp ra mắt: ${movie.title}',
      'body': 'Đừng bỏ lỡ bộ phim được mong đợi này!',
      'payload': movie.id.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      upcomingMovieChannel.id,
      upcomingMovieChannel.name,
      channelDescription: upcomingMovieChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        movie.id, // ID thông báo duy nhất
        'Sắp ra mắt: ${movie.title}',
        'Đừng bỏ lỡ bộ phim được mong đợi này!',
        platformChannelSpecifics,
        // Gửi ID phim làm payload
        payload: movie.id.toString());
  }

  /// Lên lịch thông báo vào một thời điểm cụ thể.
  ///
  /// [scheduledDate] là thời điểm trong tương lai mà thông báo sẽ được hiển thị.
  Future<void> scheduleNotification({
    required Movie movie,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    // Tăng số lượng badge trước khi lên lịch thông báo
    await _incrementBadgeCount();

    // Lưu thông báo vào DB
    await _dbHelper.insertAppNotification({
      'movie_id': movie.id,
      'title': title,
      'body': body,
      'payload': movie.id.toString(),
      // Lưu thời điểm sẽ gửi, không phải thời điểm hiện tại
      'timestamp': scheduledDate.toIso8601String(),
    });

    await flutterLocalNotificationsPlugin.zonedSchedule(
      movie.id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          scheduledChannel.id,
          scheduledChannel.name,
          channelDescription: scheduledChannel.description,
          priority: Priority.high,
        ),
      ),
      payload: movie.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Hủy một thông báo đã được lên lịch dựa trên ID của nó.
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Kiểm tra xem một thông báo với ID cụ thể đã được lên lịch hay chưa.
  Future<bool> isNotificationScheduled(int id) async {
    final List<PendingNotificationRequest> pendingRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    // Kiểm tra xem có yêu cầu nào trong danh sách có ID trùng khớp không.
    return pendingRequests.any((req) => req.id == id);
  }

  // --- Quản lý Badge ---

  Future<void> _incrementBadgeCount() async {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt('badge_count') ?? 0;
      currentCount++;
      await prefs.setInt('badge_count', currentCount);
      FlutterAppBadger.updateBadgeCount(currentCount);
    }
  }

  /// Xóa huy hiệu trên biểu tượng ứng dụng.
  /// Gọi hàm này khi người dùng mở ứng dụng.
  static Future<void> clearAppBadge() async {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_count', 0);
      FlutterAppBadger.removeBadge();
    }
  }
}
