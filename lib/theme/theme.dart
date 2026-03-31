import 'package:flutter/material.dart';

class AppThemes {
  // 🎨 Cinematic Deep Theme Palette
  static const Color deepNavy = Color(0xFF0A0E1F);
  static const Color royalPurple = Color(0xFF2E1A47);
  static const Color electricBlue = Color(0xFF246BFD);
  static const Color softViolet = Color(0xFF8B5CF6);
  static const Color slateGray = Color(0xFF9CA3AF);
  static const Color whiteSmoke = Color(0xFFF5F5F5);
  static const Color amberGlow = Color(0xFFFACC15);

  // 🌇 Theme sáng (nền sáng trung tính)
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    primaryColor: electricBlue,
    colorScheme: const ColorScheme.light(
      primary: electricBlue,
      secondary: softViolet,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: electricBlue,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  );

  // 🌌 Theme tối - Cinematic Deep Neon
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepNavy,
    primaryColor: electricBlue,
    // Sử dụng Material 3 để có các hiệu ứng và component mới nhất
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: electricBlue,
      secondary: softViolet,
      surface: royalPurple,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: whiteSmoke,
      error: Colors.redAccent,
    ),

    // ✨ AppBar Gradient ánh tím-xanh
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      shadowColor: softViolet.withOpacity(0.3),
    ),

    // 💫 Bottom Nav — màu nổi nhẹ
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: royalPurple.withOpacity(0.9),
      selectedItemColor: electricBlue,
      unselectedItemColor: slateGray,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    // 🔤 Text với ánh sáng tím-xanh
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: whiteSmoke,
        fontSize: 16,
      ),
      titleLarge: TextStyle(
        color: softViolet,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: electricBlue, blurRadius: 12),
        ],
      ),
    ),

    // 🎞️ Card và Poster
    cardTheme: CardThemeData(
      color: royalPurple.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      shadowColor: softViolet.withOpacity(0.4),
    ),

    // 🔘 Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricBlue,
        foregroundColor: Colors.white,
        shadowColor: softViolet,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),

    // ✏️ Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: royalPurple.withOpacity(0.5),
      hintStyle: const TextStyle(color: slateGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softViolet, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: electricBlue, width: 2),
      ),
    ),
  );
}
