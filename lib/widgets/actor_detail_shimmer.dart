import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ActorDetailShimmer extends StatelessWidget {
  const ActorDetailShimmer({super.key});

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
              height: 400.0,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Biography title placeholder
                  Container(
                    width: 150.0,
                    height: 24.0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8.0),
                  ),
                  // Biography text placeholder
                  _buildPlaceholderLine(double.infinity),
                  _buildPlaceholderLine(double.infinity),
                  _buildPlaceholderLine(250.0),
                  const SizedBox(height: 24.0),
                  // "Known For" title placeholder
                  Container(
                    width: 120.0,
                    height: 24.0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12.0),
                  ),
                  // Horizontal movie list placeholder
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 225,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderLine(double width) {
    return Container(
      width: width,
      height: 16.0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 4.0),
    );
  }
}
