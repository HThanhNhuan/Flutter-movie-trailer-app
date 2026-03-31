import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme/theme.dart';
import '../providers/movie_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/movie_list.dart';
import '../models/movie.dart';
import '../widgets/popular_movie_slider.dart';
import '../widgets/home_screen_shimmer.dart';
import '../widgets/movie_card_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // ✅ 1. Controller cho hiệu ứng lấp lánh
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MovieProvider>(context, listen: false);
      if (provider.popularMovies.isEmpty) {
        provider.fetchAllMovies(context);
      }
    });
    // Khởi tạo controller
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _sparkleController.dispose(); // ✅ Nhớ dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        // ✅ 4. Drawer hiện đại hơn (Glass Neon)
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppThemes.deepNavy, AppThemes.royalPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ✅ 3. Làm "DrawerHeader" bật sáng hơn (Highlight neon)
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemes.deepNavy.withOpacity(0.8),
                        AppThemes.royalPurple.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemes.softViolet.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border(
                      bottom: BorderSide(
                        color: AppThemes.electricBlue.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/logo.png', height: 40),
                      const SizedBox(width: 10),
                      const Text(
                        'PuTa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                color: AppThemes.electricBlue, blurRadius: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                    icon: Icons.category, title: 'Thể Loại', onTap: () {}),
                _buildDrawerItem(
                    icon: Icons.movie, title: 'Phim Lẻ', onTap: () {}),
                _buildDrawerItem(
                    icon: Icons.tv, title: 'Phim Bộ', onTap: () {}),
                _buildDrawerItem(
                    icon: Icons.public, title: 'Quốc Gia', onTap: () {}),
                const Divider(),
                Consumer<ThemeProvider>(builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    title: const Text("Chế độ nền tối"),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeThumbColor: AppThemes.electricBlue,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.nowPlayingMovies.isEmpty) {
            return const HomeScreenShimmer();
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllMovies(context),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  // Làm cho AppBar "nổi" trên nội dung
                  floating: true,
                  pinned: true,
                  snap: false,
                  // Làm cho AppBar trong suốt để hòa vào nền
                  backgroundColor: Colors.transparent, // Giữ nguyên
                  elevation: 0,
                  // ✅ 1. Thêm AppBar Gradient "Living Bar" với hiệu ứng kính mờ
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      // 🔹 (c) Giảm opacity blur
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        // ⚠️ 2. Thêm lớp nền để hiệu ứng blur rõ hơn
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                  // Nút mở Drawer (dấu ba gạch)
                  // ⚠️ 3. Fix lỗi "Scaffold.of() called with a context that does not contain a Scaffold"
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  // Logo làm tiêu đề
                  title: Image.asset('assets/logo.png', height: 30),
                  centerTitle: true,
                  // Nút tìm kiếm bên phải
                  actions: [
                    Consumer<NotificationProvider>(
                      builder: (context, notifProvider, _) {
                        // ✅ 1. Sử dụng Badge để hiển thị số thông báo
                        return Badge(
                          label: Text(notifProvider.unreadCount.toString()),
                          offset:
                              const Offset(-6, 6), // Điều chỉnh vị trí badge
                          isLabelVisible: notifProvider.unreadCount > 0,
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            tooltip: 'Thông báo',
                            onPressed: () {
                              // Điều hướng và xóa chấm đỏ
                              context.push('/notifications');
                              notifProvider.clear();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Phần nội dung chính được đặt trong SliverList
                SliverList(
                  delegate: SliverChildListDelegate([
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PopularMovieSlider(movies: provider.popularMovies),
                        // ✅ 2. Thêm hiệu ứng "Gradient Fade" giữa các khu vực
                        Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppThemes.deepNavy,
                              ],
                            ),
                          ),
                        ),
                        // 🎬 Now Playing Section
                        _buildMovieSection(
                          title: '🎥 Now Playing',
                          gradientColors: [
                            Colors.deepPurpleAccent.withOpacity(0.6),
                            Colors.blueAccent.withOpacity(0.4)
                          ],
                          movies: provider.nowPlayingMovies,
                          onScrollToEnd: provider.fetchMoreNowPlayingMovies,
                          hasMore: provider.hasMoreNowPlaying,
                          style: MovieCardStyle.staticGlow,
                        ),

                        // 🌟 Top Rated Section
                        _buildMovieSection(
                          title: '⭐ Top Rated',
                          gradientColors: [
                            Colors.amberAccent.withOpacity(0.5),
                            Colors.deepOrange.withOpacity(0.4)
                          ],
                          movies: provider.topRatedMovies,
                          onScrollToEnd: provider.fetchMoreTopRatedMovies,
                          hasMore: provider.hasMoreTopRated,
                          style: MovieCardStyle.pulsingGlow,
                        ),

                        // 🚀 Upcoming Section
                        _buildMovieSection(
                          title: '🚀 Upcoming',
                          gradientColors: [
                            Colors.pinkAccent.withOpacity(0.5),
                            Colors.purpleAccent.withOpacity(0.4)
                          ],
                          movies: provider.upcomingMovies,
                          onScrollToEnd: provider.fetchMoreUpcomingMovies,
                          hasMore: provider.hasMoreUpcoming,
                          style: MovieCardStyle.gradientOverlay,
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget phụ để tạo các mục trong Drawer cho đẹp và gọn
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // 🧩 Helper để xây dựng các section phim
  Widget _buildMovieSection({
    required String title,
    required List<Color> gradientColors,
    required List<Movie> movies,
    required Future<void> Function() onScrollToEnd,
    required bool hasMore,
    required MovieCardStyle style,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Tiêu đề có glow nhẹ và hiệu ứng lấp lánh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Stack(
              clipBehavior: Clip.none, // Cho phép painter vẽ ra ngoài
              children: [
                // Lớp dưới: Hiệu ứng phát sáng nhẹ phía sau chữ
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.2
                      ..color = Colors.white.withOpacity(0.7),
                    shadows: [
                      Shadow(
                        color: gradientColors.first.withOpacity(0.8),
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: gradientColors.last.withOpacity(0.7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                // Lớp trên: Chữ chính có gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white, // Màu này sẽ bị ghi đè bởi shader
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Lớp vẽ hiệu ứng lấp lánh
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, _) {
                      // ✅ 1. Sử dụng RepaintBoundary để tối ưu hóa
                      return RepaintBoundary(
                        child: CustomPaint(
                          isComplex:
                              true, // Gợi ý cho engine rằng painter này phức tạp
                          painter: _SparklePainter(
                              animation: _sparkleController,
                              sparkleColor: gradientColors.last),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ✅ Thêm lại hiệu ứng nền mờ cho khu vực danh sách phim
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors.first.withOpacity(0.25),
                        gradientColors.last.withOpacity(0.15)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MovieList(
                    title: '', // Tiêu đề đã được hiển thị ở trên
                    movies: movies,
                    onScrollToEnd: onScrollToEnd,
                    hasMore: hasMore,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 3. Custom Painter để vẽ hiệu ứng lấp lánh
class _SparklePainter extends CustomPainter {
  final Animation<double> animation;
  final Color sparkleColor;
  final _random = Random();
  final List<_Sparkle> _sparkles = [];
  // ✅ 2. Tạo đối tượng Paint một lần và tái sử dụng
  final Paint _paint = Paint()..strokeCap = StrokeCap.round;

  _SparklePainter({required this.animation, required this.sparkleColor})
      : super(repaint: animation) {
    // Tạo một vài hạt lấp lánh ban đầu
    for (var i = 0; i < 5; i++) {
      _sparkles.add(_Sparkle(_random, sparkleColor));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in _sparkles) {
      // Cập nhật vị trí và độ mờ của mỗi hạt
      sparkle.update(animation.value, size);

      // Vẽ hạt lấp lánh
      _paint.color = sparkle.color.withOpacity(sparkle.opacity);
      _paint.strokeWidth = sparkle.size;
      canvas.drawPoints(PointMode.points, [sparkle.position], _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => false;
}

// ✅ 4. Model cho một hạt lấp lánh
class _Sparkle {
  final Random random;
  late Offset position;
  late Color color;
  late double size;
  late double opacity;
  final double speed;

  _Sparkle(this.random, Color baseColor)
      : speed = random.nextDouble() * 0.5 + 0.2 {
    color = HSLColor.fromColor(baseColor).withLightness(0.8).toColor();
    position = Offset(random.nextDouble(), random.nextDouble());
    size = random.nextDouble() * 2.0 + 1.0;
  }

  void update(double progress, Size area) {
    // Di chuyển và reset vị trí
    final newY = (position.dy + speed * 0.01) % area.height;
    position = Offset(position.dx, newY);

    // Tạo hiệu ứng nhấp nháy
    opacity =
        (0.5 + (sin((position.dy / area.height + progress) * 2 * pi) * 0.5))
            .clamp(0.0, 1.0);

    // Thay đổi vị trí X ngẫu nhiên khi nó đi hết màn hình
    if (position.dy < speed * 0.01 * 60) {
      // Reset khi nó quay lại từ đầu
      position = Offset(random.nextDouble(), newY);
    }
  }
}
