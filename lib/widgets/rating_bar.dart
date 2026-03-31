import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final double voteAverage;
  final double iconSize;
  final TextStyle? textStyle;
  final Color? starColor;

  const RatingBar({
    super.key,
    required this.voteAverage,
    this.iconSize = 16.0,
    this.textStyle,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: starColor ?? Colors.amber, size: iconSize),
        const SizedBox(width: 4.0),
        Text(voteAverage.toStringAsFixed(1),
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
