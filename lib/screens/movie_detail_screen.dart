import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../providers/palette_provider.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../api/api_constants.dart';
import '../api/api_service.dart';
import '../models/movie.dart';
import '../models/cast.dart';
import '../models/movie_image.dart';
import '../models/video.dart';
import '../widgets/movie_list.dart';
import '../providers/favorites_provider.dart';
import '../widgets/rating_bar.dart';
import '../widgets/movie_detail_shimmer.dart';
import 'package:palette_generator/palette_generator.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final Movie? movie; // Make movie object optional
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Movie> _movieFuture;
  late Future<List<Cast>> _castFuture;
  late Future<List<Movie>> _recommendationsFuture;
  late Future<List<Movie>> _similarMoviesFuture;
  late Future<List<MovieImage>> _imagesFuture;
  late Future<List<Video>> _videosFuture;
  final ApiService _apiService = ApiService();
  bool _isVideosExpanded = false;
  bool _isOverviewExpanded = false;

  @override
  void initState() {
    super.initState();
    // Always fetch the full movie details to ensure all data is present
    _movieFuture = _apiService.getMovieDetail(widget.movieId);
    _castFuture = _apiService.getMovieCast(widget.movieId);
    _recommendationsFuture = _apiService.getRecommendedMovies(widget.movieId);
    _similarMoviesFuture = _apiService.getSimilarMovies(widget.movieId);
    _imagesFuture = _apiService.getMovieImages(widget.movieId);
    _videosFuture = _apiService.getMovieVideos(widget.movieId);
  }

  @override
  void dispose() {
    // Xóa palette khi màn hình bị hủy để không ảnh hưởng đến màn hình khác
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaletteProvider>(context, listen: false).clearPalette();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MovieDetailShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Movie not found'));
          }

          // Use the fresh data from the future, but fall back to the passed movie object if needed
          final movie = snapshot.data ?? widget.movie!;
          // Gọi provider để tạo palette
          if (movie.posterPath != null) {
            Provider.of<PaletteProvider>(context, listen: false)
                .generatePalette(movie.posterPath!);
          }
          return Consumer<PaletteProvider>(
            builder: (context, palette, child) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300.0,
                    pinned: true,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground
                      ],
                      title: Text(movie.title,
                          style: const TextStyle(
                              fontSize: 16, shadows: [Shadow(blurRadius: 6)])),
                      background: _buildSliverAppBarBackground(movie, palette),
                    ),
                    backgroundColor: palette.dominantColor,
                    actions: [
                      Consumer<FavoritesProvider>(
                        builder: (context, provider, child) {
                          final isFavorite = provider.isFavorite(movie.id);
                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              provider.toggleFavorite(movie);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildAboutSection(movie, palette),
                        _buildProductionCompaniesSection(movie),
                        _buildBackdropsSection(palette),
                        _buildTrailersSection(palette),
                        _buildRelatedMoviesSection(palette),
                        _buildCastSection(palette),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBarBackground(Movie movie, PaletteProvider palette) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          // ✅ Tạo tag duy nhất bằng cách kết hợp ID phim và một giá trị ngẫu nhiên hoặc timestamp
          // Sửa lại để khớp với cả MovieList và NotificationsScreen
          tag:
              'movie-poster-${movie.id}${widget.movie?.character != null ? '-related' : ''}',
          flightShuttleBuilder: (flightContext, animation, flightDirection,
              fromHeroContext, toHeroContext) {
            final hero = toHeroContext.widget as Hero;
            // Thêm hiệu ứng lật 3D khi "bay"
            return RotationTransition(
              turns: animation.drive(
                Tween<double>(begin: 0.95, end: 1.0).chain(
                  CurveTween(curve: Curves.easeInOut),
                ),
              ),
              child: hero.child,
            );
          },
          child: AnimatedBuilder(
            animation:
                const AlwaysStoppedAnimation(null), // Không cần animation ở đây
            builder: (context, child) {
              return Container(
                // Thêm hiệu ứng glow phát sáng theo màu của poster
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: palette.vibrantColor.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]),
                child: movie.posterPath != null
                    ? CachedNetworkImage(
                        imageUrl:
                            '${ApiConstants.imageBaseUrl}${movie.posterPath}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.movie, size: 100),
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: const Center(
                            child: Icon(Icons.movie,
                                size: 100, color: Colors.white))),
              );
            },
          ),
        ),
        // Add a gradient overlay to make the title more readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                palette.dominantColor.withOpacity(0.8),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // Glassmorphism effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Movie movie, PaletteProvider palette) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingBar(
                voteAverage: movie.voteAverage,
                starColor: palette.vibrantColor,
                iconSize: 20,
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.lightVibrantColor,
                    ),
              ),
              Text(' / 10', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(palette),
          const SizedBox(height: 16),
          Text('Overview',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: palette.dominantColor)),
          const SizedBox(height: 8),
          AnimatedSize(
            // Giữ lại để có hiệu ứng đẹp
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Text(
              movie.overview,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: _isOverviewExpanded ? null : 4,
              overflow: TextOverflow.fade,
            ),
          ),
          if (movie.overview.length >
              150) // Chỉ hiển thị nút nếu tóm tắt đủ dài
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isOverviewExpanded = !_isOverviewExpanded;
                  });
                },
                child: Text(_isOverviewExpanded ? 'Show Less' : 'Read More'),
              ),
            ),
          _buildGenres(movie, palette), // Sửa ở đây
        ],
      ),
    );
  }

  Widget _buildGenres(Movie movie, PaletteProvider palette) {
    if (movie.genres == null || movie.genres!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: movie.genres!
            .map((genre) => GestureDetector(
                  onTap: () => context.push(
                      '/genre/${genre.id}?name=${Uri.encodeComponent(genre.name)}'),
                  child: Chip(
                    label: Text(genre.name),
                    backgroundColor: palette.lightMutedColor.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: palette.lightVibrantColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBackdropsSection(PaletteProvider palette) {
    return FutureBuilder<List<MovieImage>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Don't show while loading
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show if no images
        }

        final images = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
              child: Text('Backdrops',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return GestureDetector(
                    onTap: () {
                      final imagePaths =
                          images.map((img) => img.filePath).toList();
                      context.push('/gallery',
                          extra: {'images': imagePaths, 'index': index});
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.only(
                          left: index == 0 ? 16 : 8,
                          right: index == images.length - 1 ? 16 : 0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.imageBaseUrl}${image.filePath}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCastSection(PaletteProvider palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cast', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FutureBuilder<List<Cast>>(
            future: _castFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator.adaptive()));
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const SizedBox(
                    height: 120,
                    child:
                        Center(child: Text('No cast information available.')));
              }

              final castList = snapshot.data!;

              return SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: castList.length,
                  itemBuilder: (context, index) {
                    final castMember = castList[index];
                    return GestureDetector(
                      onTap: () => context.push('/actor/${castMember.id}'),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: palette.vibrantColor, width: 2)),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.grey.shade800,
                                backgroundImage: castMember.profilePath != null
                                    ? CachedNetworkImageProvider(
                                        '${ApiConstants.imageBaseUrl}${castMember.profilePath}')
                                    : null,
                                child: castMember.profilePath == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              castMember.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedMoviesSection(PaletteProvider palette) {
    // Wait for both futures to complete
    return FutureBuilder<List<List<Movie>>>(
      future: Future.wait([_recommendationsFuture, _similarMoviesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final recommendations = snapshot.data![0];
        final similarMovies = snapshot.data![1];

        // Combine and remove duplicates
        final combined = <int, Movie>{};
        for (var movie in recommendations) {
          combined[movie.id] = movie;
        }
        for (var movie in similarMovies) {
          combined[movie.id] = movie;
        }

        if (combined.values.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort the combined list by voteAverage in descending order
        // Lọc ra bộ phim hiện tại khỏi danh sách phim liên quan để tránh trùng lặp Hero tag
        final sortedMovies = combined.values.toList()
          ..removeWhere((movie) => movie.id == widget.movieId)
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

        return MovieList(
          title: 'You Might Also Like',
          movies: sortedMovies,
          titleColor: palette.dominantColor, // Sửa ở đây
          heroTagSuffix: 'related', // Thêm hậu tố để tag không bị trùng
        );
      },
    );
  }

  Widget _buildTrailersSection(PaletteProvider palette) {
    return FutureBuilder<List<Video>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Không hiển thị gì khi đang tải
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Không hiển thị nếu không có video
        }
        final allVideos =
            snapshot.data!.where((video) => video.site == 'YouTube').toList();

        if (allVideos.isEmpty) {
          return const SizedBox.shrink();
        }

        final videosToShow =
            _isVideosExpanded ? allVideos : allVideos.take(2).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Videos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: videosToShow.map((video) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: palette.mutedColor.withOpacity(0.2),
                      child: ListTile(
                        leading: Image.network(
                            'https://img.youtube.com/vi/${video.key}/0.jpg'),
                        title: Text(video.name),
                        subtitle: Text(video.type),
                        onTap: () => context.push('/player', extra: {
                          'videos': allVideos,
                          'initialIndex': allVideos.indexOf(video)
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (allVideos.length > 2)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isVideosExpanded = !_isVideosExpanded;
                      });
                    },
                    child: Text(_isVideosExpanded ? 'Show Less' : 'Show More'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(PaletteProvider palette) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final videos = await _videosFuture;
              final trailer = videos.firstWhere(
                  (v) => v.type == 'Trailer' && v.site == 'YouTube',
                  orElse: () => videos.firstWhere((v) => v.site == 'YouTube',
                      orElse: () => Video(
                          id: '', key: '', name: '', site: '', type: '')));
              if (trailer.key.isNotEmpty) {
                context.push('/player', extra: {
                  'videos': videos,
                  'initialIndex': videos.indexOf(trailer)
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No playable video found.')),
                );
              }
            },
            icon: const Icon(Icons.play_arrow, color: AppThemes.amberGlow),
            label: const Text(
              'Watch Trailer',
              style: TextStyle(
                color: AppThemes.amberGlow,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: AppThemes.electricBlue, blurRadius: 10),
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.vibrantColor.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Download functionality not implemented yet.')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.mutedColor),
              foregroundColor: palette.lightMutedColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductionCompaniesSection(Movie movie) {
    if (movie.productionCompanies == null ||
        movie.productionCompanies!.isEmpty) {
      return const SizedBox.shrink();
    }

    final companies = movie.productionCompanies!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Companies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final company = companies[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.white.withOpacity(0.9),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: company.logoPath != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        '${ApiConstants.imageBaseUrl}${company.logoPath}',
                                    fit: BoxFit.contain,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.business,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
