import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../providers/wishlist_provider.dart';

class WishlistButton extends ConsumerWidget {
  const WishlistButton({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(wishlistProvider
        .select((items) => items.any((p) => p.id == product.id)));
    return IconButton.filledTonal(
      tooltip: context.tr(saved ? 'Remove from wishlist' : 'Save to wishlist'),
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      onPressed: () async {
        try {
          await ref.read(wishlistProvider.notifier).toggle(product);
        } catch (_) {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context
                    .tr('Could not save favourites. Please try again.'))));
        }
      },
    );
  }
}
