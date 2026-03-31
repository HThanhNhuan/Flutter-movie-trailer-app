import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../api/api_constants.dart';
import '../models/movie.dart';
import 'rating_bar.dart';
import 'movie_card_style.dart';
import '../theme/theme.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final bool useSmallImage;
  final VoidCallback onTap;
  final String? heroTagSuffix;
  final ScrollController? scrollController; // For parallax effect
  final VoidCallback? onRemove; // Thêm callback để xóa
  final MovieCardStyle style;

  const MovieCard({
    super.key,
    required this.movie,
    this.useSmallImage = true,
    this.heroTagSuffix,
    this.onRemove,
    this.scrollController,
    this.style = MovieCardStyle.normal,
    required this.onTap,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  void _onScroll() => setState(() {});

  @override
  Widget build(BuildContext context) {
    Widget cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.05 : 1.0,
        child: Hero(
          tag: widget.heroTagSuffix != null
              ? 'movie-poster-${widget.movie.id}-${widget.heroTagSuffix}'
              : 'movie-poster-${widget.movie.id}',
          child: Material(
            color: Colors.transparent, // Giữ nền trong suốt
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: _buildCardStack(),
              ),
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }

  Widget _buildCardStack() {
    // This method should only return the inner content of the card,
    // as the Hero, InkWell, and other decorations are handled in the main `build` method.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Movie Poster Image with Parallax Effect
        if (widget.movie.posterPath != null) ...[
          Builder(
            key: _imageKey,
            builder: (context) {
              double itemOffset = 0.0;
              if (context.findRenderObject() != null &&
                  widget.scrollController?.hasClients == true) {
                final renderBox = context.findRenderObject() as RenderBox;
                // Get the card's position relative to the screen
                final cardPosition = renderBox.localToGlobal(Offset.zero);
                itemOffset = cardPosition.dx;
              }
              // Calculate parallax offset
              final parallaxOffset = itemOffset * 0.15;

              return Transform.translate(
                offset: Offset(parallaxOffset, 0),
                child: CachedNetworkImage(
                  imageUrl:
                      '${ApiConstants.smallImageBaseUrl}${widget.movie.posterPath}',
                  fit: BoxFit.cover,
                  memCacheHeight: 300,
                ),
              );
            },
          )
        ] else
          const Center(child: Icon(Icons.movie)),
        // Gradient overlay for text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        // Style overlay for 'Upcoming'
        if (widget.style == MovieCardStyle.gradientOverlay)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.15),
                    AppThemes.deepNavy.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        // Movie Title
        Positioned(
          bottom: 8.0,
          left: 8.0,
          right: 8.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.movie.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              RatingBar(
                voteAverage: widget.movie.voteAverage,
                textStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
              if (widget.movie.character != null &&
                  widget.movie.character!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'as ${widget.movie.character}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // Nút xóa (chỉ hiển thị nếu có callback onRemove)
        if (widget.onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withOpacity(0.5),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: widget.onRemove,
                tooltip: 'Remove from favorites',
              ),
            ),
          ),
      ],
    );
  }
}
