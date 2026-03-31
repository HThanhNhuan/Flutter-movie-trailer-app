import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MovieDetailShimmer extends StatelessWidget {
  const MovieDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar placeholder
            Container(
              height: 300.0,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating placeholder
                  _buildPlaceholderLine(100),
                  const SizedBox(height: 16),
                  // Buttons placeholder
                  Row(
                    children: [
                      Expanded(
                          child: _buildPlaceholderLine(double.infinity,
                              height: 48)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildPlaceholderLine(double.infinity,
                              height: 48)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Overview title placeholder
                  _buildPlaceholderLine(150, height: 24),
                  const SizedBox(height: 8),
                  // Overview text placeholder
                  _buildPlaceholderLine(double.infinity),
                  _buildPlaceholderLine(double.infinity),
                  _buildPlaceholderLine(250.0),
                  const SizedBox(height: 16),
                  // Genres placeholder
                  Row(
                    children: List.generate(
                        3,
                        (index) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: _buildPlaceholderLine(80, height: 30),
                            )),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderLine(double width, {double height = 16.0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
    );
  }
}
