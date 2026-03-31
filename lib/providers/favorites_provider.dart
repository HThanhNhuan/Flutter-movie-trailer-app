import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../data/database_helper.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Movie> _favorites = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Movie> get favorites => _favorites;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoriteMovies = await _dbHelper.getFavorites();
    _favorites.clear();
    _favorites.addAll(favoriteMovies);
    notifyListeners();
  }

  Future<void> toggleFavorite(Movie movie) async {
    final isFav = isFavorite(movie.id);

    if (isFav) {
      _favorites.removeWhere((fav) => fav.id == movie.id);
      await _dbHelper.deleteFavorite(movie.id);
    } else {
      _favorites.add(movie);
      await _dbHelper.insertFavorite(movie);
    }
    notifyListeners();
  }

  bool isFavorite(int movieId) {
    return _favorites.any((movie) => movie.id == movieId);
  }

  void addFavorite(Movie movie) {
    if (!isFavorite(movie.id)) {
      toggleFavorite(movie);
    }
  }

  void removeFavorite(int movieId) {
    if (isFavorite(movieId)) {
      final movie = _favorites.firstWhere((m) => m.id == movieId);
      toggleFavorite(movie);
    }
  }

  /// Xóa một phim khỏi danh sách tại một vị trí (index) cụ thể và trả về phim đã xóa.
  /// Cần thiết cho việc tạo animation trong AnimatedGrid/AnimatedList.
  Movie removeFavoriteAt(int index) {
    final movie = _favorites.removeAt(index);
    _dbHelper.deleteFavorite(movie.id);
    notifyListeners(); // Vẫn thông báo để các phần khác của UI (nếu có) được cập nhật
    return movie;
  }
}
