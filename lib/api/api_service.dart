import 'dart:convert';
import '../models/movie.dart';
import 'api_constants.dart';
import '../models/actor.dart';
import '../models/video.dart';
import '../models/cast.dart';
import '../models/movie_image.dart';

import 'package:http/http.dart' as http;

class ApiService {
  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/now_playing?api_key=${ApiConstants.apiKey}&page=$page');
  }

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/popular?api_key=${ApiConstants.apiKey}&page=$page');
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/top_rated?api_key=${ApiConstants.apiKey}&page=$page');
  }

  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/upcoming?api_key=${ApiConstants.apiKey}&page=$page');
  }

  Future<List<Movie>> searchMovies(String query) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/search/movie?query=$query&api_key=${ApiConstants.apiKey}');
  }

  Future<Movie> getMovieDetail(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&append_to_response=production_companies,genres'));
    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie detail');
    }
  }

  Future<List<Cast>> getMovieCast(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId/credits?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['cast'] as List;
      return decodedBody.map((cast) => Cast.fromJson(cast)).toList();
    } else {
      throw Exception('Failed to load movie cast');
    }
  }

  Future<Actor> getActorDetails(int personId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/person/$personId?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      return Actor.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load actor details');
    }
  }

  Future<List<Movie>> getActorMovies(int personId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/person/$personId/movie_credits?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['cast'] as List;
      // Lọc ra các phim trùng lặp và sắp xếp theo độ phổ biến
      final movies = decodedBody.map((movie) => Movie.fromJson(movie)).toList();
      return movies;
    } else {
      throw Exception('Failed to load actor movies');
    }
  }

  Future<List<Movie>> getRecommendedMovies(int movieId) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/$movieId/recommendations?api_key=${ApiConstants.apiKey}');
  }

  Future<List<Movie>> getSimilarMovies(int movieId) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/movie/$movieId/similar?api_key=${ApiConstants.apiKey}');
  }

  Future<List<MovieImage>> getMovieImages(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId/images?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['backdrops'] as List;
      return decodedBody.map((image) => MovieImage.fromJson(image)).toList();
    } else {
      throw Exception('Failed to load movie images');
    }
  }

  Future<List<Video>> getMovieVideos(int movieId) async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/movie/$movieId/videos?api_key=${ApiConstants.apiKey}'));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['results'] as List;
      return decodedBody.map((video) => Video.fromJson(video)).toList();
    } else {
      throw Exception('Failed to load movie videos');
    }
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    return _getMovies(
        '${ApiConstants.baseUrl}/discover/movie?api_key=${ApiConstants.apiKey}&with_genres=$genreId&page=$page');
  }

  Future<List<Movie>> _getMovies(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body)['results'] as List;
      return decodedBody.map((movie) => Movie.fromJson(movie)).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
