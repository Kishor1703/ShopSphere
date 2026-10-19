import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/cart_providers.dart';
import '../widgets/cart_item_tile.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final checkout = ref.watch(checkoutProvider);

    ref.listen(checkoutProvider.select((s) => s.errorMessage), (_, message) {
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$message Your cart is unchanged.'),
            action: SnackBarAction(
              label: context.tr('Retry'),
              onPressed: () => _placeOrder(context, ref),
            ),
          ),
        );
      ref.read(checkoutProvider.notifier).dismissError();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          summary.itemCount == 0
              ? 'Your cart'
              : 'Your cart (${summary.itemCount})',
        ),
      ),
      body: SafeArea(
        child: items.isEmpty
            ? EmptyView(
                icon: Icons.shopping_cart_outlined,
                title: context.tr('Your cart is empty'),
                message: 'Add something you like and it will show up here.',
                actionLabel: 'Browse products',
                onAction: () => context.go('/home'),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide = context.screenSize != ScreenSize.compact;
                  final list = _ItemList(items: items);
                  final panel = _SummaryPanel(
                    summary: summary,
                    submitting: checkout.isSubmitting,
                    onPlaceOrder: () => _placeOrder(context, ref),
                  );
                  if (!sideBySide) {
                    return Column(
                      children: [
                        Expanded(child: list),
                        panel,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: list),
                      SizedBox(
                        width: 380,
                        child: SingleChildScrollView(child: panel),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(checkoutProvider.notifier).placeOrder();
    if (success && context.mounted) context.go('/order-success');
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return CartItemTile(
          key: ValueKey(item.productId),
          item: item,
          onTap: () => context.push('/product/${item.productId}'),
          onQuantityChanged: (q) => notifier.setQuantity(item.productId, q),
          onRemove: () {
            notifier.remove(item.productId);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Removed ${item.title}.')),
              );
          },
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.submitting,
    required this.onPlaceOrder,
  });

  final CartSummary summary;
  final bool submitting;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(String label, String value,
        {bool strong = false, Color? color}) {
      final style = strong
          ? theme.textTheme.titleLarge
          : theme.textTheme.bodyLarge?.copyWith(color: color);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr(label), style: style),
            Text(value, style: style),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('Subtotal', formatPrice(summary.subtotal)),
          row(
            'Discount',
            '-${formatPrice(summary.discount)}',
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF81DCA9)
                : AppColors.success,
          ),
          const Divider(),
          row('Total', formatPrice(summary.total), strong: true),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: submitting ? null : onPlaceOrder,
            child: submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(context.tr('Place order')),
          ),
        ],
      ),
    );
  }
}
