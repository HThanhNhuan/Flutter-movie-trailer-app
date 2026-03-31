import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/about_screen.dart';
import '../screens/actor_detail_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/genre_movies_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_wrapper.dart';
import '../models/movie.dart';
import '../screens/movie_detail_screen.dart';
import '../models/video.dart';
import '../screens/notifications_screen.dart';
import '../screens/search_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // ✅ Chỉ tạo một instance GoRouter duy nhất
  static final GoRouter router = GoRouter(
    initialLocation: '/home', // Sẽ được override trong main nếu cần
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainWrapper(child: child); // Wrapper with BottomNavBar
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const FavoritesScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: MovieDetailScreen(
              movieId: int.parse(state.pathParameters['id']!),
              movie: state.extra as Movie?,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/actor/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final actorId = int.parse(state.pathParameters['id']!);
          return ActorDetailScreen(actorId: actorId);
        },
      ),
      GoRoute(
        path: '/genre/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final genreId = int.parse(state.pathParameters['id']!);
          final genreName = state.uri.queryParameters['name'] ?? 'Genre';
          return GenreMoviesScreen(genreId: genreId, genreName: genreName);
        },
      ),
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final videos = args['videos'] as List<Video>;
          final initialIndex = args['initialIndex'] as int;
          return VideoPlayerScreen(videos: videos, initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/gallery',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return GalleryScreen(
            imagePaths: args['images'] as List<String>,
            initialIndex: args['index'] as int,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
