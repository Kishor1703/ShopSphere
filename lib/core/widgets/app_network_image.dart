import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Cached network image with a loading placeholder and a graceful fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? url;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final address = url;
    if (address == null || address.isEmpty) return _fallback(context);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: address,
        fit: fit,
        placeholder: (context, _) => const SkeletonBox(radius: 0),
        errorWidget: (context, _, __) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
