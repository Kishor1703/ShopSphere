import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/wishlist_button.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Wishlist'))),
      body: items.isEmpty
          ? EmptyView(
              icon: Icons.favorite_border,
              title: context.tr('Your wishlist is empty'),
              message: context.tr('Tap a heart to save products for later.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = items[index];
                return Card(
                    child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: AppNetworkImage(
                          url: product.thumbnail, fit: BoxFit.contain)),
                  title: Text(product.title),
                  subtitle: Text(formatPrice(product.discountedPrice)),
                  trailing: WishlistButton(product: product),
                  onTap: () => context.push('/product/${product.id}'),
                ));
              },
            ),
    );
  }
}
