import 'package:flutter/material.dart';
import 'dart:math';

class PosterGlow extends StatefulWidget {
  final Widget child;
  final double glowIntensity;
  final Color glowColor;
  final double borderRadius;
  final Duration duration;

  const PosterGlow({
    super.key,
    required this.child,
    this.glowIntensity = 0.4,
    this.glowColor = Colors.cyanAccent,
    this.borderRadius = 14,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<PosterGlow> createState() => _PosterGlowState();
}

class _PosterGlowState extends State<PosterGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _glow = Tween<double>(
            begin: 0.1, end: widget.glowIntensity) // Start with a minimum glow
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_glow.value),
                blurRadius: 15 + (_glow.value * 10),
                spreadRadius: 3 + (_glow.value * 2),
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
