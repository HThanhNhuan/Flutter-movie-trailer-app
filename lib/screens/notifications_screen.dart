import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import 'dart:math';
import '../providers/notification_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/animated_neon_background.dart';
import '../models/movie.dart';
import '../api/api_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  // --- State cho việc phân trang ---
  final List<Map<String, dynamic>> _notifications = [];
  final Map<String, List<Map<String, dynamic>>> _notificationsByCategory = {
    'recommendation': [],
    'trending': [],
    'upcoming': [],
  };
  // ✅ 1. Thêm GlobalKey cho mỗi AnimatedList
  final Map<String, GlobalKey<AnimatedListState>> _listKeys = {
    'recommendation': GlobalKey<AnimatedListState>(),
    'trending': GlobalKey<AnimatedListState>(),
    'upcoming': GlobalKey<AnimatedListState>(),
  };
  final Map<String, bool> _isLoadingMore = {
    'recommendation': false,
    'trending': false,
    'upcoming': false
  };
  final Map<String, bool> _hasMore = {
    'recommendation': true,
    'trending': true,
    'upcoming': true
  };
  final Map<String, ScrollController> _scrollControllers = {};
  static const int _pageSize = 20;
  // ---------------------------------

  bool _isFetching = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _pulseController;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ScrollController cho mỗi tab
    for (var category in _notificationsByCategory.keys) {
      _scrollControllers[category] = ScrollController()
        ..addListener(() => _onScroll(category));
    }

    // Khi người dùng vào màn hình này, reset badge count trên UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cập nhật lại số lượng từ DB để đảm bảo chính xác
      Provider.of<NotificationProvider>(context, listen: false)
          .refreshUnreadCount();
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadInitialNotifications();
    _fetchAndSaveMovies();
  }

  // Hàm tải dữ liệu ban đầu cho tất cả các category
  Future<void> _loadInitialNotifications() async {
    for (var category in _notificationsByCategory.keys) {
      _loadNotifications(category, isInitialLoad: true);
    }
  }

  // Hàm tải thông báo theo từng category, hỗ trợ phân trang
  Future<void> _loadNotifications(String category,
      {bool isInitialLoad = false}) async {
    if (_isLoadingMore[category]! || !_hasMore[category]!) return;

    setState(() {
      _isLoadingMore[category] = true;
    });

    final currentList = _notificationsByCategory[category]!;
    final offset = isInitialLoad ? 0 : currentList.length;

    // Lấy thông báo từ DB với limit và offset
    final notifs = await _dbHelper.getNotificationsByCategory(category,
        limit: _pageSize, offset: offset);
    if (!mounted) return;

    // Nếu không có dữ liệu mới, đánh dấu là đã hết
    if (notifs.length < _pageSize) {
      _hasMore[category] = false;
    }

    final mutableNotifs =
        notifs.map((e) => Map<String, dynamic>.from(e)).toList();

    setState(() {
      if (isInitialLoad) currentList.clear();
      currentList.addAll(mutableNotifs);
      _isLoadingMore[category] = false;
    });
  }

  // ✅ Hàm chèn thông báo mới vào AnimatedList với hiệu ứng
  void _insertNewNotifications(List<Map<String, dynamic>> newNotifications) {
    if (!mounted) return;

    for (final notif in newNotifications) {
      final category = notif['category'] as String;
      final list = _notificationsByCategory[category];
      final listKey = _listKeys[category];

      if (list != null && listKey?.currentState != null) {
        list.insert(0, notif);
        listKey?.currentState?.insertItem(1, duration: const Duration(milliseconds: 500)); // +1 vì có header
      }
    }
  }

  // ✅ Hàm lấy phim mới từ TMDb và lưu vào DB
  Future<void> _fetchAndSaveMovies() async {
    if (_isFetching) return;
    _refreshController.forward(from: 0);
    setState(() => _isFetching = true);
    try {
      final tmdb = TmdbService();
      // Danh sách để thu thập các thông báo thực sự mới
      final List<Map<String, dynamic>> newlyAddedNotifications = [];

      // Chạy song song cả 2 API
      final results = await Future.wait([
        tmdb.fetchUpcomingMovies(),
        tmdb.fetchTrendingMovies(),
      ]);
      final upcomingMovies = results[0];
      final trendingMovies = results[1];

      for (final movie in upcomingMovies.take(5)) {
        final notificationData = {
          'movie_id': movie['id'],
          'category': 'upcoming',
          'title': '🎬 Sắp chiếu: ${movie['title']}',
          'body': 'Ra mắt ngày ${movie['release_date'] ?? 'chưa xác định'}',
          'poster_path': movie['poster_path'],
          'payload': movie['id'].toString(),
          'timestamp': DateTime.now().toIso8601String()
        };
        final newId = await _dbHelper.insertAppNotification(notificationData);
        if (newId > 0) {
          newlyAddedNotifications.add({...notificationData, 'id': newId, 'is_read': 0});
        }
      }

      for (final movie in trendingMovies.take(3)) {
        final notificationData = {
          'movie_id': movie['id'],
          'category': 'trending',
          'title': '🔥 Đang hot: ${movie['title']}',
          'body': movie['overview'] ?? 'Không có mô tả.',
          'poster_path': movie['poster_path'],
          'payload': movie['id'].toString(),
          'timestamp': DateTime.now().toIso8601String()
        };
        final newId = await _dbHelper.insertAppNotification(notificationData);
        if (newId > 0) {
          newlyAddedNotifications.add({...notificationData, 'id': newId, 'is_read': 0});
        }
      }

      // Lấy phim đề xuất dựa trên phim yêu thích đầu tiên
      final favorites = await _dbHelper.getFavorites();
      if (favorites.isNotEmpty) {
        final firstFav = favorites.first;
        final recMovies = await tmdb.fetchRecommendedMovies(firstFav.id);
        for (final movie in recMovies.take(3)) {
          final notificationData = {
            'movie_id': movie['id'],
            'category': 'recommendation',
            'title': '💖 Dành cho bạn: ${movie['title']}',
            'body': movie['overview'] ?? 'Phim gợi ý dựa trên sở thích của bạn.',
            'poster_path': movie['poster_path'],
            'payload': movie['id'].toString(),
            'timestamp': DateTime.now().toIso8601String()
          };
          final newId = await _dbHelper.insertAppNotification(notificationData);
          if (newId > 0) {
            newlyAddedNotifications.add({...notificationData, 'id': newId, 'is_read': 0});
          }
        }
      }
      // Thay vì tải lại toàn bộ, chỉ chèn các mục mới
      _insertNewNotifications(newlyAddedNotifications.reversed.toList());
    } catch (e) {
      debugPrint('⚠️ Lỗi khi tải phim từ TMDb: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _onScroll(String category) {
    final controller = _scrollControllers[category]!;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      // Khi người dùng cuộn gần đến cuối, tải thêm dữ liệu
      _loadNotifications(category);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Thông báo'),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          actions: [
            if (_isFetching)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              // ✨ Animation khi refresh
              IconButton(
                icon: AnimatedRotation(
                  turns: _refreshController.value,
                  duration: const Duration(seconds: 1),
                  child: const Icon(Icons.refresh),
                ),
                tooltip: 'Cập nhật phim mới',
                onPressed: _fetchAndSaveMovies,
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa tất cả thông báo',
              onPressed: () async {
                await _dbHelper.deleteAllNotifications();
                _loadInitialNotifications();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '💖 Dành cho Bạn'),
              Tab(text: '🔥 Đang Hot'),
              Tab(text: '🎬 Sắp Chiếu'),
            ],
          ),
        ),
        body: AnimatedNeonBackground(
          child: Stack(
            children: [
              // 🎥 Hiệu ứng "Cinematic Background Transition"
              if (_notificationsByCategory['recommendation']!.isNotEmpty &&
                  _notificationsByCategory['recommendation']
                          ?.first['poster_path'] !=
                      null)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: CachedNetworkImage(
                      imageUrl:
                          '${ApiConstants.imageBaseUrl}${_notificationsByCategory['recommendation']?.first['poster_path']}',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.85),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                ),
              TabBarView(
                children: [
                  _buildNotificationList('recommendation'),
                  _buildNotificationList('trending'),
                  _buildNotificationList('upcoming'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 1. Hàm helper để nhóm thông báo theo ngày
  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate(
      List<Map<String, dynamic>> notifications) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Hôm nay': [],
      'Hôm qua': [],
      'Tuần này': [],
      'Cũ hơn': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    // Monday of the current week
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));

    for (final notif in notifications) {
      final timestamp = DateTime.parse(notif['timestamp']);
      final notifDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (notifDate.isAtSameMomentAs(today)) {
        grouped['Hôm nay']!.add(notif);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        grouped['Hôm qua']!.add(notif);
      } else if (notifDate.isAfter(startOfWeek) || notifDate.isAtSameMomentAs(startOfWeek)) {
        grouped['Tuần này']!.add(notif);
      } else {
        grouped['Cũ hơn']!.add(notif);
      }
    }
    // Xóa các nhóm rỗng
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  Widget _buildNotificationList(String category) {
    final notificationsForCategory = _notificationsByCategory[category]!;
    final hasMoreForCategory = _hasMore[category]!;

    // 🌈 Gradient riêng từng tab
    final gradientColors = switch (category) {
      'recommendation' => [
          AppThemes.electricBlue.withOpacity(0.85),
          AppThemes.softViolet.withOpacity(0.85)
        ],
      'trending' => [
          Colors.deepOrangeAccent.withOpacity(0.9),
          Colors.redAccent.withOpacity(0.8)
        ],
      'upcoming' => [
          AppThemes.deepNavy.withOpacity(0.85),
          AppThemes.royalPurple.withOpacity(0.8)
        ],
      _ => [
          AppThemes.royalPurple.withOpacity(0.8),
          AppThemes.deepNavy.withOpacity(0.8)
        ]
    };

    // ✅ 2. Nhóm thông báo trước khi hiển thị
    final groupedNotifications = _groupNotificationsByDate(notificationsForCategory);

    // 🔔 Thông điệp đầu mỗi tab
    String? headerMessage;
    IconData? headerIcon;
    Color? headerColor;
    if (category == 'recommendation') {
      headerMessage = '💡 Phim được gợi ý dựa trên sở thích của bạn!';
      headerIcon = Icons.favorite;
      headerColor = Colors.pinkAccent;
    } else if (category == 'trending') {
      headerMessage = '🔥 Phim đang được xem nhiều nhất hôm nay!';
      headerIcon = Icons.local_fire_department_rounded;
      headerColor = Colors.orangeAccent;
    } else if (category == 'upcoming') {
      headerMessage = '🎬 Chuẩn bị ra mắt — đừng bỏ lỡ!';
      headerIcon = Icons.access_time;
      headerColor = Colors.amberAccent;
    }

    if (notificationsForCategory.isEmpty && !_isLoadingMore[category]!) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 60, color: Colors.white54),
            SizedBox(height: 12),
            Text('Không có thông báo nào trong mục này.',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
          ],
        ),
      );
    }

    // Tính toán tổng số item (header nhóm + item thông báo)
    int totalItemCount = groupedNotifications.length; // Số lượng header
    groupedNotifications.forEach((key, value) {
      totalItemCount += value.length;
    });
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: AnimationLimiter(
        // ✅ 2. Thay thế ListView.separated bằng AnimatedList
        child: AnimatedList(
          key: _listKeys[category], // Sử dụng GlobalKey
          controller: _scrollControllers[category],
          padding: EdgeInsets.only(
            top: kToolbarHeight +
                kTextTabBarHeight +
                MediaQuery.of(context).padding.top +
                16,
            left: 8,
            right: 8,
            bottom: 16,
          ),
          initialItemCount: totalItemCount + 2, // +2 for main header and loader
          itemBuilder: (context, index, animation) {
            // --- Logic mới để render danh sách đã nhóm ---

            // 1. Render header chính của tab
            if (index == 0) {
              if (headerMessage == null) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(headerIcon, color: headerColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          headerMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: headerColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                  color: headerColor!.withOpacity(0.7),
                                  blurRadius: 10)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            // 2. Render loading indicator ở cuối
            if (index == totalItemCount + 1) {
              return hasMoreForCategory
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()))
                  : const SizedBox.shrink();
            }

            // 3. Logic tìm và render header nhóm hoặc item thông báo
            int currentIndex = 1; // Bắt đầu từ 1 vì đã có header chính
            for (var groupKey in groupedNotifications.keys) {
              final groupItems = groupedNotifications[groupKey]!;
              // Kiểm tra xem index hiện tại có phải là header của nhóm này không
              if (index == currentIndex) {
                return _buildGroupHeader(groupKey);
              }
              currentIndex++; // Tăng index cho header

              // Kiểm tra xem index có nằm trong nhóm item này không
              if (index < currentIndex + groupItems.length) {
                final itemIndexInGroup = index - currentIndex;
                final notif = groupItems[itemIndexInGroup];
                // --- Phần render item giữ nguyên như cũ ---
                return _buildNotificationItem(
                  context: context,
                  notif: notif,
                  animation: animation,
                  gradientColors: gradientColors,
                  category: category,
                  onDismissed: () {
                     // Logic xóa item khi dismiss
                    final originalIndex = notificationsForCategory.indexOf(notif);
                    notificationsForCategory.removeAt(originalIndex);

                    _listKeys[category]!.currentState!.removeItem(
                        index,
                        (context, animation) => _buildRemovedItem(notif, gradientColors, animation),
                        duration: const Duration(milliseconds: 300));

                    _showUndoSnackBar(notif, originalIndex, index, category);
                  }
                );
              }
              currentIndex += groupItems.length; // Tăng index cho các item trong nhóm
            }

            // Fallback, không nên xảy ra
            return const SizedBox.shrink();
            /* final notif = notificationsForCategory[index - 1];
            final timestamp = DateTime.parse(notif['timestamp']);

            return AnimationConfiguration.staggeredList(
              position: index - 1,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                verticalOffset: 50.0, // Hiệu ứng trượt lên
                child: FadeInAnimation(
                  child: Dismissible(
                    key: Key(notif['id'].toString()),
                    direction: DismissDirection.endToStart,
                    // ✅ 3. Cập nhật logic xóa để tránh xung đột animation
                    onDismissed: (direction) {
                      // --- Logic xóa với chức năng Hoàn tác ---

                      // 1. Lấy ra item và vị trí của nó
                      final removedItemIndex = index - 1;
                      final removedItem = notificationsForCategory[removedItemIndex];

                      // 2. Tạm thời xóa khỏi danh sách dữ liệu và cập nhật UI
                      notificationsForCategory.removeAt(removedItemIndex);
                      _listKeys[category]!.currentState!.removeItem(
                          index, // Index trong itemBuilder bao gồm cả header
                          (context, animation) => _buildRemovedItem(removedItem, gradientColors, animation));
                      
                      // 3. Hiển thị SnackBar với nút "Hoàn tác"
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      final snackBar = SnackBar(
                        content: Text('Đã xóa: ${removedItem['title']}'),
                        action: SnackBarAction(
                          label: 'Hoàn tác',
                          onPressed: () {
                            // Nếu người dùng hoàn tác, chèn lại item vào danh sách và UI
                            notificationsForCategory.insert(removedItemIndex, removedItem);
                            _listKeys[category]!.currentState!.insertItem(index);
                          },
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
                        // 4. Nếu SnackBar đóng mà không phải do nhấn "Hoàn tác", thì mới xóa khỏi DB
                        if (reason != SnackBarClosedReason.action) {
                          _dbHelper.deleteNotification(removedItem['id'] as int);
                        }
                      });
                    },
                    background: Container(
                      color: Colors.red.withOpacity(0.8),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Hero(
                          tag: 'movie-poster-${notif['movie_id']}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: notif['poster_path'] != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        '${ApiConstants.smallImageBaseUrl}${notif['poster_path']}',
                                    width: 50,
                                    // ✅ Tối ưu bộ nhớ: resize ảnh trước khi cache
                                    memCacheHeight: 150, // ~ (50 * 3) cho màn hình HDPI
                                    placeholder: (context, url) => Container(color: Colors.black26),
                                    errorWidget: (context, url, error) => const Icon(Icons.movie_creation_outlined),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.movie_creation_outlined,
                                    color: AppThemes.electricBlue, size: 28),
                          ),
                        ),
                        title: Text(
                          notif['title'] ?? 'No Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['body'] ?? 'No Body',
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(timestamp),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                // 📆 Lịch chiếu – đếm ngược thời gian
                                if (category ==
                                        'upcoming' && // ⏳ Hiện đếm ngược cho “Sắp chiếu”
                                    notif['body'] != null &&
                                    notif['body'].contains('Ra mắt ngày'))
                                  _buildCountdown(notif['body']),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          // Đánh dấu đã đọc khi nhấn vào
                          if (notif['is_read'] == 0) {
                            await _dbHelper
                                .markNotificationAsRead(notif['id'] as int);
                            setState(() {
                              final i = notificationsForCategory
                                  .indexWhere((n) => n['id'] == notif['id']);
                              if (i != -1) {
                                notificationsForCategory[i]['is_read'] = 1;
                              }
                            });
                          }
                          // Điều hướng đến chi tiết phim
                          if (notif['payload'] != null) {
                            context.push('/movie/${notif['payload']}',
                                extra: Movie.fromJson({
                                  'id': notif[
                                      'movie_id'], // Đảm bảo id được truyền đúng
                                  'poster_path': notif['poster_path']
                                }));
                          }
                        },
                        // Hiển thị chấm xanh nếu chưa đọc
                        trailing: notif['is_read'] == 0
                            ? _buildGlowPulse() // 💫 "Notification Glow Pulse"
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ); */
          },
        ),
      ),
    );
  }

  // Widget này được dùng để render item khi nó đang được animate xóa đi
  Widget _buildNotificationItem({
    required BuildContext context,
    required Map<String, dynamic> notif,
    required Animation<double> animation,
    required List<Color> gradientColors,
    required String category,
    required VoidCallback onDismissed,
  }) {
    final timestamp = DateTime.parse(notif['timestamp']);
    return AnimationConfiguration.staggeredList(
      position: notif['id'] as int, // Dùng ID để position ổn định
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Dismissible(
            key: ValueKey(notif['id']), // Sử dụng ValueKey
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => onDismissed(),
            background: Container(
              color: Colors.red.withOpacity(0.8),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                leading: Hero(
                  tag: 'movie-poster-${notif['movie_id']}',
                  // ✅ Thêm flightShuttleBuilder để tạo hiệu ứng lật 3D
                  flightShuttleBuilder: (flightContext, animation,
                      flightDirection, fromHeroContext, toHeroContext) {
                    final hero = toHeroContext.widget as Hero;
                    // Hiệu ứng xoay khi chuyển trang
                    return RotationTransition(
                      turns: animation.drive(
                        Tween<double>(begin: 0.5, end: 1.0).chain(
                          CurveTween(curve: Curves.easeInOut),
                        ),
                      ),
                      child: hero.child,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: notif['poster_path'] != null
                        ? CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.smallImageBaseUrl}${notif['poster_path']}',
                            width: 50,
                            // ✅ Tối ưu bộ nhớ: resize ảnh trước khi cache
                            memCacheHeight: 150, // ~ (50 * 3) cho màn hình HDPI
                            placeholder: (context, url) =>
                                Container(color: Colors.black26),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.movie_creation_outlined),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.movie_creation_outlined,
                            color: AppThemes.electricBlue, size: 28),
                  ),
                ),
                title: Text(notif['title'] ?? 'No Title',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                subtitle: _buildItemSubtitle(notif, timestamp, category),
                onTap: () => _onItemTap(notif, category),
                trailing:
                    notif['is_read'] == 0 ? _buildGlowPulse() : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tách widget item ra để tái sử dụng trong `_buildRemovedItem`
  Widget _buildRemovedItem(Map<String, dynamic> notif,
      List<Color> gradientColors, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0), // = separator height / 2
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: notif['poster_path'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl:
                          '${ApiConstants.smallImageBaseUrl}${notif['poster_path']}',
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.movie_creation_outlined,
                    color: AppThemes.electricBlue, size: 28),
            title: Text(
              notif['title'] ?? 'No Title',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(notif['body'] ?? 'No Body',
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    );
  }
  // Widget cho hiệu ứng "Glow Pulse"

  Widget _buildGlowPulse() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final size = 10 + sin(_pulseController.value * 2 * pi) * 2;
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 6)])
        );
        },
      );
  }

  // Widget cho đếm ngược
  Widget _buildCountdown(String body) {
    try {
      final releaseDateString = body.split('Ra mắt ngày ').last;
      final releaseDate = DateFormat('yyyy-MM-dd').parse(releaseDateString);
      final remaining = releaseDate.difference(DateTime.now()).inDays;
      if (remaining >= 0) {
        return Text('🎞️ Còn ${remaining + 1} ngày!',
            style: const TextStyle(
                color: Colors.amberAccent, fontWeight: FontWeight.bold));
      }
    } catch (e) {/* Bỏ qua nếu không parse được ngày */}
    return const SizedBox.shrink();
  }

  // ✅ Widget cho tiêu đề nhóm
  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✅ Tách logic subtitle của item ra
  Widget _buildItemSubtitle(
      Map<String, dynamic> notif, DateTime timestamp, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notif['body'] ?? 'No Body',
          style: const TextStyle(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              DateFormat.yMMMd().add_jm().format(timestamp),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Spacer(),
            if (category == 'upcoming' &&
                notif['body'] != null &&
                notif['body'].contains('Ra mắt ngày'))
              _buildCountdown(notif['body']),
          ],
        ),
      ],
    );
  }

  // ✅ Tách logic khi nhấn vào item
  void _onItemTap(Map<String, dynamic> notif, String category) async {
    if (notif['is_read'] == 0) {
      await _dbHelper.markNotificationAsRead(notif['id'] as int);
      setState(() {
        final list = _notificationsByCategory[category]!;
        final i = list.indexWhere((n) => n['id'] == notif['id']);
        if (i != -1) {
          list[i]['is_read'] = 1;
        }
      });
    }
    if (notif['payload'] != null) {
      context.push('/movie/${notif['payload']}',
          extra: Movie.fromJson(
              {'id': notif['movie_id'], 'poster_path': notif['poster_path']}));
    }
  }

  // ✅ Tách logic hiển thị SnackBar Hoàn tác
  void _showUndoSnackBar(Map<String, dynamic> removedItem, int originalIndex,
      int listIndex, String category) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Text('Đã xóa: ${removedItem['title']}'),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () {
          _notificationsByCategory[category]!.insert(originalIndex, removedItem);
          _listKeys[category]!.currentState!.insertItem(listIndex);
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        _dbHelper.deleteNotification(removedItem['id'] as int);
      }
    });
  }
}
