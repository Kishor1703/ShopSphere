import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';

/// Loads and displays one product. Used by the detail page and by the
/// master-detail pane on expanded screens.
class ProductDetailView extends ConsumerWidget {
  const ProductDetailView({
    super.key,
    required this.productId,
    this.useHero = false,
  });

  final int productId;
  final bool useHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));

    return async.when(
      loading: () => const _DetailSkeleton(),
      error: (error, _) {
        final failure = error is Failure ? error : null;
        if (failure?.type == FailureType.notFound) {
          return EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Product not found',
            message: 'This product may have been removed or never existed.',
            actionLabel: 'Back to shop',
            onAction: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          );
        }
        return ErrorView(
          message: failure?.message ?? 'We could not load this product.',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        );
      },
      data: (product) => _DetailContent(product: product, useHero: useHero),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1.3, child: SkeletonBoxFill()),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 24, width: 240),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(height: 18, width: 120),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 14),
          SizedBox(height: 6),
          SkeletonBox(height: 14),
        ],
      ),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({required this.product, required this.useHero});

  final Product product;
  final bool useHero;

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  int _quantity = 1;

  void _addToCart() {
    final result =
        ref.read(cartProvider.notifier).add(widget.product, _quantity);
    final message = switch (result) {
      AddToCartResult.added => 'Added to your cart.',
      AddToCartResult.limitedByStock =>
        'Only ${widget.product.stock} in stock. Your cart holds the maximum.',
      AddToCartResult.outOfStock => 'This product is out of stock.',
      AddToCartResult.invalidQuantity => 'Choose a quantity of at least 1.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    final gallery = _ImageCarousel(
      product: product,
      useHero: widget.useHero,
    );
    final info = _InfoColumn(
      product: product,
      quantity: _quantity,
      onQuantityChanged: (q) => setState(() => _quantity = q),
      onAddToCart: _addToCart,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: gallery),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: info),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [gallery, const SizedBox(height: AppSpacing.md), info],
            ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.product, required this.useHero});

  final Product product;
  final bool useHero;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _images {
    final p = widget.product;
    if (p.images.isNotEmpty) return p.images;
    if (p.thumbnail.isNotEmpty) return [p.thumbnail];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: ColoredBox(
              color: AppColors.productBackdrop,
              child: images.isEmpty
                  ? const AppNetworkImage(url: null)
                  : PageView.builder(
                      controller: _controller,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final image = AppNetworkImage(
                          url: images[i],
                          fit: BoxFit.contain,
                          semanticLabel:
                              '${widget.product.title}, image ${i + 1}',
                        );
                        return i == 0 && widget.useHero
                            ? Hero(
                                tag: 'product-image-${widget.product.id}',
                                child: image,
                              )
                            : image;
                      },
                    ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Image ${_index + 1} of ${images.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _index ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoColumn extends ConsumerWidget {
  const _InfoColumn({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxQuantity = product.stock < 1 ? 1 : product.stock;
    final safeQuantity =
        quantity < 1 ? 1 : (quantity > maxQuantity ? maxQuantity : quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title, style: theme.textTheme.headlineSmall),
        if (product.brand != null && product.brand!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            product.brand!,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatPrice(product.discountedPrice),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (product.hasDiscount) ...[
              Text(
                formatPrice(product.price),
                style: theme.textTheme.titleSmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${formatDiscount(product.discountPercentage)} off',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            RatingBadge(rating: product.rating),
            const SizedBox(width: AppSpacing.md),
            _StockLabel(stock: product.stock),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(product.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('Quantity', style: theme.textTheme.titleSmall),
            const Spacer(),
            QuantitySelector(
              value: safeQuantity,
              max: maxQuantity,
              onChanged: product.inStock ? onQuantityChanged : (_) {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: product.inStock ? onAddToCart : null,
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text(product.inStock ? 'Add to cart' : 'Out of stock'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Customer reviews', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (product.reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final review in product.reviews) _ReviewTile(review: review),
      ],
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = stock < 1
        ? ('Out of stock', scheme.error)
        : stock <= 5
            ? (
                'Only $stock left',
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFC078)
                    : const Color(0xFFB45309)
              )
            : (
                'In stock',
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF81DCA9)
                    : AppColors.success
              );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = formatIsoDate(review.date);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RatingBadge(rating: review.rating.toDouble()),
            ],
          ),
          if (date.isNotEmpty)
            Text(
              date,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.comment, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
