import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:timezone/data/latest.dart' as tz;

import '../providers/favorites_provider.dart';
import '../providers/movie_provider.dart';
import '../providers/palette_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../router/app_router.dart';
import '../theme/theme.dart';
import '../widgets/animated_neon_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 Lấy payload từ thông báo đã khởi chạy ứng dụng (nếu có)
  String? initialRoute;
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await NotificationService()
          .flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      initialRoute = '/movie/$payload';
    }
  }

  // ✅ Cấu hình initialLocation cho router duy nhất nếu cần
  if (initialRoute != null) {
    AppRouter.router.go(initialRoute);
  }

  tz.initializeTimeZones(); // Khởi tạo timezones
  NotificationService.clearAppBadge(); // Xóa badge khi mở app
  await NotificationService().init(); // Khởi tạo notification service

  // Bọc ứng dụng trong ProviderScope để quản lý trạng thái Riverpod
  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends StatelessWidget {
  final String? initialRoute;
  const MyApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(create: (_) => MovieProvider()),
        legacy.ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        legacy.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        legacy.ChangeNotifierProvider(create: (_) => PaletteProvider()),
        legacy.ChangeNotifierProvider(
            create: (_) => NotificationProvider()), // Thêm provider mới
      ],
      child: legacy.Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;

          return MaterialApp.router(
            title: 'Movie App',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            routerConfig: AppRouter.router, // ✅ Sử dụng router tĩnh
            // ✅ Đặt AnimatedNeonBackground vào đây
            builder: (context, router) => AnimatedNeonBackground(
              // router chính là child mà GoRouter tạo ra
              child: router ?? const SizedBox(),
            ),
          );
        },
      ),
    );
  }
}
