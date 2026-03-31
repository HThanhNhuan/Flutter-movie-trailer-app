import 'package:flutter/material.dart';
import 'dart:math';

class NoiseLayer extends StatelessWidget {
  const NoiseLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _NoisePainter(),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final Random _random = Random();
  final List<Offset> _points = [];

  _NoisePainter() {
    for (int i = 0; i < 2000; i++) {
      _points.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03);
    for (final point in _points) {
      canvas.drawRect(
          Rect.fromLTWH(point.dx * size.width, point.dy * size.height, 1, 1),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
