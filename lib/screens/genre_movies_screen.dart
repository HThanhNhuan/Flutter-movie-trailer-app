import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';

class GenreMoviesScreen extends StatefulWidget {
  final int genreId;
  final String genreName;

  const GenreMoviesScreen(
      {super.key, required this.genreId, required this.genreName});

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final List<Movie> _movies = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchMovies();
    }
  }

  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newMovies = await _apiService.getMoviesByGenre(widget.genreId,
          page: _currentPage);
      if (newMovies.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _movies.addAll(newMovies);
          _currentPage++;
        });
      }
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.genreName),
        ),
        body: _movies.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _movies.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _movies.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final movie = _movies[index];
                  return MovieCard(
                    movie: movie,
                    onTap: () =>
                        context.push('/movie/${movie.id}', extra: movie),
                  );
                },
              ));
  }
}
