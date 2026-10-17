import 'package:flutter/material.dart';

/// Asset-free brand mark that inherits the current app color scheme.
class ShopSphereLogo extends StatelessWidget {
  const ShopSphereLogo({super.key, this.size = 144});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.45,
              child: Container(
                width: size,
                height: size * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size / 2, size * 0.36),
                  ),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
            Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.23),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.onPrimaryContainer],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: size * 0.36,
                color: colors.onPrimary,
              ),
            ),
            Positioned(
              top: size * 0.17,
              right: size * 0.05,
              child: Container(
                width: size * 0.1,
                height: size * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.tertiary,
                  border: Border.all(color: colors.surface, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
