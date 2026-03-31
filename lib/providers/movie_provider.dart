import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_service.dart';
import '../models/movie.dart';
import '../services/notification_service.dart';
import '../services/tmdb_service.dart';
import '../data/database_helper.dart';
import 'notification_provider.dart';
import 'dart:math';

class MovieProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final TmdbService _tmdbService = TmdbService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Movie> _nowPlayingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];
  List<Movie> _searchedMovies = [];

  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMoreNowPlaying = true;
  bool _hasMoreTopRated = true;
  bool _hasMoreUpcoming = true;

  int _nowPlayingPage = 1;
  int _topRatedPage = 1;
  int _upcomingPage = 1;

  // Getters
  List<Movie> get nowPlayingMovies => _nowPlayingMovies;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<Movie> get searchedMovies => _searchedMovies;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get hasMoreNowPlaying => _hasMoreNowPlaying;
  bool get hasMoreTopRated => _hasMoreTopRated;
  bool get hasMoreUpcoming => _hasMoreUpcoming;

  // Cần BuildContext để truy cập NotificationProvider
  Future<void> fetchAllMovies(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch all categories in parallel
      final results = await Future.wait([
        _apiService.getNowPlayingMovies(),
        _apiService.getPopularMovies(),
        _apiService.getTopRatedMovies(),
        _apiService.getUpcomingMovies(),
      ]);

      _nowPlayingMovies = results[0];
      _popularMovies = results[1];
      _topRatedMovies = results[2];
      _upcomingMovies = results[3];

      // Reset pagination
      _nowPlayingPage = 2;
      _topRatedPage = 2;
      _upcomingPage = 2;
      _hasMoreNowPlaying = _nowPlayingMovies.length == 20;
      _hasMoreTopRated = _topRatedMovies.length == 20;
      _hasMoreUpcoming = _upcomingMovies.length == 20;

      // Send notification for a random upcoming movie
      if (_upcomingMovies.isNotEmpty) {
        final randomMovie =
            _upcomingMovies[Random().nextInt(_upcomingMovies.length)];
        await _notificationService.showUpcomingMovieNotification(randomMovie);
        // Cập nhật lại số lượng thông báo chưa đọc
        Provider.of<NotificationProvider>(context, listen: false)
            .refreshUnreadCount();
      }

      // Lấy phim sắp chiếu và lưu vào DB dưới dạng thông báo
      try {
        final upcomingForNotif = await _tmdbService.fetchUpcomingMovies();
        for (final movie in upcomingForNotif.take(5)) {
          await _dbHelper.insertAppNotification({
            'movie_id': movie['id'],
            'category': 'upcoming',
            'title': 'Phim sắp chiếu: ${movie['title']}',
            'body': 'Ra mắt ngày ${movie['release_date'] ?? 'chưa xác định'}',
            'poster_path': movie['poster_path'], // ✅ Thêm poster_path
            'payload': movie['id'].toString(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        // Lấy phim trending và lưu vào DB
        final trendingMovies = await _tmdbService.fetchTrendingMovies();
        for (final movie in trendingMovies.take(3)) {
          await _dbHelper.insertAppNotification({
            'movie_id': movie['id'],
            'category': 'trending',
            'title': '🔥 Đang hot: ${movie['title']}',
            'body': movie['overview'] ?? 'Không có mô tả.',
            'poster_path': movie['poster_path'],
            'payload': movie['id'].toString(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        // Cập nhật lại số lượng sau khi thêm thông báo mới
        Provider.of<NotificationProvider>(context, listen: false)
            .refreshUnreadCount();
      } catch (e) {/* Bỏ qua lỗi nếu không lấy được tin tức */}
    } catch (e) {
      // Handle error if needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreNowPlayingMovies() async {
    if (_isLoading || !_hasMoreNowPlaying) return;
    _isLoading = true;

    final newMovies =
        await _apiService.getNowPlayingMovies(page: _nowPlayingPage);
    if (newMovies.length < 20) {
      _hasMoreNowPlaying = false;
    }
    _nowPlayingMovies.addAll(newMovies);
    _nowPlayingPage++;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreTopRatedMovies() async {
    if (_isLoading || !_hasMoreTopRated) return;
    _isLoading = true;

    final newMovies = await _apiService.getTopRatedMovies(page: _topRatedPage);
    if (newMovies.length < 20) {
      _hasMoreTopRated = false;
    }
    _topRatedMovies.addAll(newMovies);
    _topRatedPage++;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreUpcomingMovies() async {
    if (_isLoading || !_hasMoreUpcoming) return;
    _isLoading = true;

    final newMovies = await _apiService.getUpcomingMovies(page: _upcomingPage);
    if (newMovies.length < 20) {
      _hasMoreUpcoming = false;
    }
    _upcomingMovies.addAll(newMovies);
    _upcomingPage++;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchedMovies = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();

    try {
      _searchedMovies = await _apiService.searchMovies(query);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
