import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';

class TmdbService {
  Future<List<Map<String, dynamic>>> fetchUpcomingMovies() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/movie/upcoming?api_key=${ApiConstants.apiKey}&language=vi-VN&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((movie) {
        return {
          'id': movie['id'],
          'title': movie['title'],
          'overview': movie['overview'],
          'poster_path': movie['poster_path'],
          'release_date': movie['release_date'],
          'genre_ids': movie['genre_ids'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch upcoming movies');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrendingMovies() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/trending/movie/day?api_key=${ApiConstants.apiKey}&language=vi-VN'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((movie) {
        return {
          'id': movie['id'],
          'title': movie['title'],
          'overview': movie['overview'],
          'poster_path': movie['poster_path'],
          'genre_ids': movie['genre_ids'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch trending movies');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecommendedMovies(int movieId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/movie/$movieId/recommendations?api_key=${ApiConstants.apiKey}&language=vi-VN&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((movie) {
        return {
          'id': movie['id'],
          'title': movie['title'],
          'overview': movie['overview'],
          'poster_path': movie['poster_path'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch recommended movies');
    }
  }
}
