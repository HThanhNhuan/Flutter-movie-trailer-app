import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../models/movie.dart';
import 'movie_card.dart';
import 'package:palette_generator/palette_generator.dart';
import 'poster_glow.dart';
import '../api/api_constants.dart';

class PopularMovieSlider extends StatefulWidget {
  final List<Movie> movies;
  const PopularMovieSlider({super.key, required this.movies});

  @override
  State<PopularMovieSlider> createState() => _PopularMovieSliderState();
}

class _PopularMovieSliderState extends State<PopularMovieSlider>
    with TickerProviderStateMixin {
  int _current = 0;
  final carousel.CarouselController _controller = carousel.CarouselController();
  late AnimationController _neonPulseController;
  late AnimationController _sparkleController;

  // Map to cache dominant colors for each movie poster
  final Map<int, Color> _dominantColors = {};

  @override
  void initState() {
    super.initState();
    _neonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _updateMovieColors();
  }

  @override
  void didUpdateWidget(PopularMovieSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.movies != oldWidget.movies) {
      _updateMovieColors();
    }
  }

  void _updateMovieColors() {
    for (final movie in widget.movies) {
      if (movie.posterPath != null && !_dominantColors.containsKey(movie.id)) {
        _generatePalette(movie);
      }
    }
  }

  Future<void> _generatePalette(Movie movie) async {
    if (movie.posterPath == null) return;
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(
            '${ApiConstants.smallImageBaseUrl}${movie.posterPath}'),
        size: const Size(100, 150), // Smaller size for faster generation
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(() {
          _dominantColors[movie.id] =
              paletteGenerator.vibrantColor?.color ?? AppThemes.softViolet;
        });
      }
    } catch (e) {
      debugPrint("Error generating palette for movie ${movie.id}: $e");
    }
  }

  @override
  void dispose() {
    _neonPulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies;

    return Container(
      child: Column(
        // The child of the Container is a Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Tiêu đề “Popular” mới cực nổi bật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.deepOrangeAccent, Colors.amberAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // 💫 Hiệu ứng sáng shimmer động
                    Shimmer.fromColors(
                      baseColor: Colors.blueAccent.shade100,
                      highlightColor: Colors.purpleAccent.shade100,
                      child: const Text(
                        "Popular",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // 🌟 Light trail lấp lánh chạy ngang
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _sparkleController,
                        builder: (context, _) {
                          final x =
                              (sin(_sparkleController.value * 2 * pi) + 1) / 2;
                          return Align(
                            alignment: Alignment(x * 2 - 1, 0),
                            child: Container(
                              width: 20,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.6),
                                    Colors.white.withOpacity(0),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ✅ Thêm hiệu ứng nền mờ cho khu vực card phim
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppThemes.electricBlue
                      .withOpacity(0.3), // Neon glow shadow
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 10, sigmaY: 10), // Điều chỉnh độ mờ
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16), // Padding bên trong nền mờ
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemes.royalPurple
                            .withOpacity(0.3), // Gradient màu nhẹ
                        AppThemes.deepNavy.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: movies.isEmpty
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'No popular movies available.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                      : SizedBox(
                          height:
                              380, // Giữ nguyên chiều cao để chứa carousel và reflection
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // 🎞️ Slider phim
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  height:
                                      300, // Quan trọng: ép chiều cao của CarouselSlider
                                  child: carousel.CarouselSlider.builder(
                                    carouselController: _controller,
                                    itemCount: movies.length,
                                    itemBuilder: (context, index, realIndex) {
                                      final movie = movies[index];
                                      final isActive = index == _current;

                                      return Transform.scale(
                                        scale: isActive ? 1.05 : 0.95,
                                        child: PosterGlow(
                                          glowColor: Colors.blueAccent,
                                          glowIntensity: 0.45,
                                          duration: isActive
                                              ? const Duration(seconds: 2)
                                              : const Duration(seconds: 5),
                                          child: MovieCard(
                                            movie: movie,
                                            onTap: () => context.push(
                                                '/movie/${movie.id}',
                                                extra: movie),
                                          ),
                                        ),
                                      );
                                    },
                                    options: carousel.CarouselOptions(
                                      height: 280,
                                      autoPlay: true,
                                      enlargeCenterPage: true,
                                      viewportFraction: 0.7,
                                      autoPlayInterval:
                                          const Duration(seconds: 4),
                                      onPageChanged: (index, reason) {
                                        setState(() => _current = index);
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // 🔮 Phản chiếu (Reflection)
                              Positioned(
                                bottom: 20,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationX(pi),
                                  child: Opacity(
                                    opacity: 0.15,
                                    child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white,
                                            Colors.transparent
                                          ],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.dstIn,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ImageFiltered(
                                          imageFilter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.6,
                                            height: 100,
                                            child: MovieCard(
                                              movie: movies[_current],
                                              onTap: () {},
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 🌈 Indicator
                              Positioned(
                                bottom: 6,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: movies.asMap().entries.map((entry) {
                                    final isActive = _current == entry.key;
                                    return GestureDetector(
                                      onTap: () =>
                                          _controller.animateToPage(entry.key),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: isActive ? 20 : 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          gradient: LinearGradient(
                                            colors: isActive
                                                ? [
                                                    Colors.cyanAccent,
                                                    Colors.deepPurpleAccent
                                                  ]
                                                : [
                                                    Colors.white24,
                                                    Colors.white10
                                                  ],
                                          ),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.cyanAccent
                                                        .withOpacity(0.8),
                                                    blurRadius: 12,
                                                    spreadRadius: 2,
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
