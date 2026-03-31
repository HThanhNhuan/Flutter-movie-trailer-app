import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreenShimmer extends StatelessWidget {
  const HomeScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: Scaffold(
        body: NestedScrollView(
          physics: const NeverScrollableScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: const Text('Movie App'),
                pinned: true,
                floating: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ];
          },
          body: const SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Popular Slider Placeholder
                _PopularSliderPlaceholder(),
                SizedBox(height: 16),
                // Movie List Placeholder
                _MovieListPlaceholder(title: 'Top Rated'),
                _MovieListPlaceholder(title: 'Now Playing'),
                _MovieListPlaceholder(title: 'Upcoming'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularSliderPlaceholder extends StatelessWidget {
  const _PopularSliderPlaceholder();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth * 0.65;
    final itemHeight = itemWidth / 1.5; // Giữ tỷ lệ aspectRatio 1.5

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlaceholderLine(100,
            height: 24, margin: const EdgeInsets.all(16)),
        SizedBox(
          height: itemHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: itemWidth,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovieListPlaceholder extends StatelessWidget {
  final String title;
  const _MovieListPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlaceholderLine(150,
            height: 24, margin: const EdgeInsets.all(16)),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => _buildPlaceholderLine(150,
                height: 250, margin: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ),
      ],
    );
  }
}

Widget _buildPlaceholderLine(double width,
    {double height = 16.0, EdgeInsetsGeometry? margin}) {
  return Container(
    width: width,
    height: height,
    margin: margin,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
