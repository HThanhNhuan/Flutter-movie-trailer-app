import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../theme/theme.dart';
import 'noise_layer.dart';

class AnimatedNeonBackground extends StatefulWidget {
  final Widget child;
  const AnimatedNeonBackground({super.key, required this.child});

  @override
  State<AnimatedNeonBackground> createState() => _AnimatedNeonBackgroundState();
}

class _AnimatedNeonBackgroundState extends State<AnimatedNeonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: AppThemes.deepNavy, // ✅ 1. Điều chỉnh sắc độ nền
      end: AppThemes.royalPurple.withOpacity(0.85),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _color2 = ColorTween(
      begin: AppThemes.deepNavy,
      end: AppThemes.electricBlue.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color1.value ?? AppThemes.deepNavy, // Sử dụng màu đã animate
                _color2.value ?? AppThemes.deepNavy, // Sử dụng màu đã animate
              ],
            ),
          ),
          child: Stack(
            children: [
              // Hiệu ứng ánh sáng chuyển động mờ
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.5 - 0.5 * _controller.value,
                        0.5 + 0.5 * _controller.value,
                      ),
                      radius: 1.2,
                      colors: [
                        AppThemes.electricBlue.withOpacity(0.25),
                        AppThemes.softViolet.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Hiệu ứng phản chiếu sàn
              Positioned(
                bottom: -100,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppThemes.softViolet.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // ✅ 5. Bonus: Ambient Light Layer
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 + 2 * _controller.value, 0),
                          end: Alignment(1 - 2 * _controller.value, 1),
                          colors: [
                            AppThemes.softViolet.withOpacity(0.05),
                            Colors.transparent,
                            AppThemes.electricBlue.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 🎥 2. Thêm "Cinema Noise Layer"
              Positioned.fill(
                child: IgnorePointer(
                  // 💡 2. Thêm một lớp Opacity động nhẹ để noise “sống”
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Opacity(
                      opacity: 0.03 + 0.02 * sin(_controller.value * 2 * pi),
                      child: const NoiseLayer(),
                    ),
                  ),
                ),
              ),
              // 🌌 2. Thêm "Depth Blur Layer"
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0.15)),
                ),
              ),
              // 🌒 Viền tối dần (vignette)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // 💡 (a) Thêm lớp sáng nhẹ trung tâm (Lens glow)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          Colors.white.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                  opacity: 0.9 + 0.1 * sin(_controller.value * 2 * pi),
                  child: widget.child),
            ],
          ),
        );
      },
    );
  }
}
