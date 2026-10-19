import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE09A00)),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: style),
          ],
        ),
      ),
    );
  }
}
