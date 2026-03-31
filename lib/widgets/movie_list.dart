import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../theme/theme.dart';
import 'movie_card.dart';
import 'movie_card_style.dart';
import 'poster_glow.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MovieList extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final Function? onScrollToEnd;
  final bool hasMore;
  final Color? titleColor;
  final String? heroTagSuffix;
  final MovieCardStyle style;

  const MovieList({
    super.key,
    required this.title,
    required this.movies,
    this.onScrollToEnd,
    this.hasMore = false,
    this.titleColor,
    this.heroTagSuffix,
    this.style = MovieCardStyle.normal,
  });

  @override
  State<MovieList> createState() => _MovieListState();
}

class _MovieListState extends State<MovieList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        widget.onScrollToEnd?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the list if there are no movies and we are not expecting more.
    if (widget.movies.isEmpty && !widget.hasMore) {
      return const SizedBox.shrink();
    }

    // Nếu tiêu đề trống, chỉ trả về phần danh sách phim
    // để sử dụng trong thiết kế section mới ở HomeScreen.
    if (widget.title.isEmpty) {
      return SizedBox(
        height: 250,
        child: AnimationLimiter(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.movies.length + (widget.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.movies.length) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              final movie = widget.movies[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: SizedBox(
                      width: 150,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Builder(builder: (context) {
                          final card = MovieCard(
                            movie: movie,
                            scrollController: _scrollController,
                            heroTagSuffix: widget.heroTagSuffix,
                            onTap: () => context.push('/movie/${movie.id}',
                                extra: movie),
                          );

                          // Apply glow based on style
                          switch (widget.style) {
                            case MovieCardStyle.staticGlow: // Now Playing
                              return PosterGlow(
                                glowColor: Colors.greenAccent,
                                glowIntensity: 0.5,
                                child: card,
                              );
                            case MovieCardStyle.pulsingGlow: // Top Rated
                              return PosterGlow(
                                glowColor: Colors.purpleAccent,
                                glowIntensity: 0.4,
                                child: card,
                              );
                            case MovieCardStyle.gradientOverlay: // Upcoming
                              return PosterGlow(
                                glowColor: Colors.orangeAccent,
                                glowIntensity: 0.55,
                                child: card,
                              );
                            default:
                              return card;
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppThemes.softViolet,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(color: AppThemes.electricBlue, blurRadius: 10),
                    ]),
              ),
              // Show "See All" only if there's no pagination logic
              if (widget.onScrollToEnd == null && widget.movies.isNotEmpty)
                TextButton(
                  onPressed: () {
                    context.push('/see-all', extra: {
                      'title': widget.title,
                      'movies': widget.movies
                    });
                  },
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          // Bọc ListView bằng AnimationLimiter
          child: AnimationLimiter(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.movies.length + (widget.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.movies.length) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }
                final movie = widget.movies[index];
                // Thêm animation cho từng item
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: SizedBox(
                        width: 150,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Builder(builder: (context) {
                            final card = MovieCard(
                              movie: movie,
                              scrollController: _scrollController,
                              heroTagSuffix: widget.heroTagSuffix,
                              onTap: () => context.push('/movie/${movie.id}',
                                  extra: movie),
                            );

                            // Apply glow based on style
                            switch (widget.style) {
                              case MovieCardStyle.staticGlow: // Now Playing
                                return PosterGlow(
                                  glowColor: Colors.greenAccent,
                                  glowIntensity: 0.5,
                                  child: card,
                                );
                              case MovieCardStyle.pulsingGlow: // Top Rated
                                return PosterGlow(
                                  glowColor: Colors.purpleAccent,
                                  glowIntensity: 0.4,
                                  child: card,
                                );
                              case MovieCardStyle.gradientOverlay: // Upcoming
                                return PosterGlow(
                                  glowColor: Colors.orangeAccent,
                                  glowIntensity: 0.55,
                                  child: card,
                                );
                              default:
                                return card;
                            }
                          }),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
