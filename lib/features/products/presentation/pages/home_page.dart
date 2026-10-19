import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_toggle.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/widgets/cart_badge_button.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = context.screenSize == ScreenSize.expanded;
    final catalogue = _Catalogue(expanded: expanded);
    if (!expanded) return catalogue;

    // Master-detail: catalogue on the left, selected product on the right.
    final selected = ref.watch(selectedProductIdProvider);
    return Row(
      children: [
        Expanded(flex: 11, child: catalogue),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 9,
          child: selected == null
              ? const EmptyView(
                  icon: Icons.touch_app_outlined,
                  title: 'Select a product',
                  message: 'Pick something from the list to see its details.',
                )
              : ProductDetailView(
                  key: ValueKey(selected),
                  productId: selected,
                ),
        ),
      ],
    );
  }
}

class _Catalogue extends ConsumerStatefulWidget {
  const _Catalogue({required this.expanded});

  final bool expanded;

  @override
  ConsumerState<_Catalogue> createState() => _CatalogueState();
}

class _CatalogueState extends ConsumerState<_Catalogue> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Restore any existing query text when the page is rebuilt.
    _searchController.text = ref.read(productListProvider).query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  /// If the first page does not fill the viewport there is nothing to scroll,
  /// so the scroll listener would never fire. Ask for more in that case.
  void _fillViewportIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.extentAfter <= 400) {
        ref.read(productListProvider.notifier).loadMore();
      }
    });
  }

  void _openProduct(Product product) {
    if (widget.expanded) {
      ref.read(selectedProductIdProvider.notifier).state = product.id;
    } else {
      context.push('/product/${product.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    // Keep the text field in sync when a category change clears the query.
    ref.listen(productListProvider.select((s) => s.query), (_, query) {
      if (_searchController.text.trim() != query) {
        _searchController.text = query;
      }
    });

    ref.listen(
        productListProvider.select((s) => (s.query, s.categorySlug, s.sort)),
        (previous, next) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  controller: _searchController,
                  sort: state.sort,
                  onChanged: notifier.onQueryChanged,
                  onClear: () {
                    _searchController.clear();
                    notifier.search('');
                  },
                  onSortSelected: notifier.setSort,
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoryChips(
                  selected: state.categorySlug,
                  onSelected: notifier.selectCategory,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              if (state.failure != null &&
                  state.products.isNotEmpty &&
                  !state.loadMoreFailed)
                SliverToBoxAdapter(
                  child: MaterialBanner(
                    content: Text(state.failure!.message),
                    actions: [
                      TextButton(
                          onPressed: notifier.refresh,
                          child: const Text('Retry refresh'))
                    ],
                  ),
                ),
              _body(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ProductListState state, ProductListNotifier notifier) {
    switch (state.status) {
      case ListStatus.initial:
      case ListStatus.loading:
        return _grid(
          itemCount: 8,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        );
      case ListStatus.failure:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.failure?.message ?? 'We could not load products.',
            onRetry: notifier.refresh,
          ),
        );
      case ListStatus.empty:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.search_off_rounded,
            title: 'No products found',
            message: state.hasActiveFilters
                ? 'Try a different search or category.'
                : 'There is nothing to show right now.',
            actionLabel: state.hasActiveFilters ? 'Clear filters' : 'Refresh',
            onAction: state.hasActiveFilters
                ? () => notifier.selectCategory(null)
                : notifier.refresh,
          ),
        );
      case ListStatus.success:
        _fillViewportIfNeeded();
        final selectedId =
            widget.expanded ? ref.watch(selectedProductIdProvider) : null;
        return _grid(
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            return ProductCard(
              product: product,
              selected: product.id == selectedId,
              onTap: () => _openProduct(product),
            );
          },
          footer: _Footer(
              state: state,
              onRetry: () {
                notifier.loadMore(retry: true);
              }),
        );
    }
  }

  Widget _grid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    Widget? footer,
  }) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const padding = AppSpacing.md;
        const spacing = AppSpacing.md;
        final width = constraints.crossAxisExtent;
        final rawColumns = (width / 190).floor();
        final columns = rawColumns < 2 ? 2 : (rawColumns > 4 ? 4 : rawColumns);
        final cellWidth =
            (width - padding * 2 - spacing * (columns - 1)) / columns;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        // Square image plus room for two title lines, price and rating.
        final cellHeight = cellWidth + 118 * textScale;

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(padding, 0, padding, padding),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: cellHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ),
            if (footer != null) SliverToBoxAdapter(child: footer),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.sort,
    required this.onChanged,
    required this.onClear,
    required this.onSortSelected,
  });

  final TextEditingController controller;
  final ProductSort sort;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<ProductSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.marine,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  size: 20,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ShopSphere',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const ThemeToggle(),
              const CartBadgeButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(
                right: AppSpacing.sm, bottom: AppSpacing.md),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A little discovery, every day.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 6),
                Text('Find your next everyday favourite.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: appInputDecoration(
                        context,
                        label: 'Search products',
                        icon: Icons.search,
                        suffix: value.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: onClear,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<ProductSort>(
                  tooltip: 'Sort products',
                  icon: const Icon(Icons.sort_rounded),
                  initialValue: sort,
                  onSelected: onSortSelected,
                  itemBuilder: (context) => [
                    for (final option in ProductSort.values)
                      CheckedPopupMenuItem<ProductSort>(
                        value: option,
                        checked: option == sort,
                        child: Text(option.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final items = categories.valueOrNull ?? const <Category>[];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final category = items[index - 1];
          return ChoiceChip(
            label: Text(category.name),
            selected: selected == category.slug,
            onSelected: (_) => onSelected(category.slug),
          );
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final ProductListState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Could not load more. Retry'),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            'You have seen everything',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.md);
  }
}
