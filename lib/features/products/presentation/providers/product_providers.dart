import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/product_usecases.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => ProductRemoteDataSource(ref.watch(dioProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider)),
);

final getProductsPageUseCaseProvider = Provider(
  (ref) => GetProductsPageUseCase(ref.watch(productRepositoryProvider)),
);
final getCategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesUseCase(ref.watch(productRepositoryProvider)),
);
final getProductUseCaseProvider = Provider(
  (ref) => GetProductUseCase(ref.watch(productRepositoryProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(getCategoriesUseCaseProvider)(),
);

/// Cached per product id so reopening a product does not refetch it.
final productDetailProvider = FutureProvider.family<Product, int>(
  (ref, id) => ref.watch(getProductUseCaseProvider)(id),
);

/// Product shown in the detail pane on expanded (master-detail) layouts.
final selectedProductIdProvider = StateProvider<int?>((ref) => null);

enum ListStatus { initial, loading, success, empty, failure }

class ProductListState extends Equatable {
  const ProductListState({
    this.status = ListStatus.initial,
    this.products = const [],
    this.query = '',
    this.categorySlug,
    this.sort = ProductSort.featured,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final ListStatus status;
  final List<Product> products;
  final String query;
  final String? categorySlug;
  final ProductSort sort;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final Failure? failure;

  bool get hasActiveFilters =>
      query.isNotEmpty || categorySlug != null;

  ProductListState copyWith({
    ListStatus? status,
    List<Product>? products,
    String? query,
    String? categorySlug,
    bool clearCategory = false,
    ProductSort? sort,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      ProductListState(
        status: status ?? this.status,
        products: products ?? this.products,
        query: query ?? this.query,
        categorySlug:
            clearCategory ? null : (categorySlug ?? this.categorySlug),
        sort: sort ?? this.sort,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        status,
        products,
        query,
        categorySlug,
        sort,
        hasMore,
        isLoadingMore,
        loadMoreFailed,
        failure,
      ];
}

/// Drives the catalogue.
///
/// Search and category are mutually exclusive: choosing a category clears the
/// search text, and typing a search clears the category. DummyJSON has no
/// endpoint combining the two, so this avoids contradictory UI. Sorting
/// applies on top of whichever one is active.
class ProductListNotifier extends Notifier<ProductListState> {
  static const pageSize = 20;
  static const debounceDuration = Duration(milliseconds: 400);

  Timer? _debounce;
  int _requestId = 0;
  int _nextSkip = 0;

  @override
  ProductListState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const ProductListState();
  }

  /// Loads the first page once. Safe to call from `initState`.
  Future<void> loadInitial() async {
    if (state.status != ListStatus.initial) return;
    await _loadFirstPage();
  }

  Future<void> refresh() => _loadFirstPage();

  /// Debounced entry point for the search field.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () => search(query));
  }

  Future<void> search(String query) {
    final trimmed = query.trim();
    if (trimmed == state.query) return Future<void>.value();
    state = state.copyWith(query: trimmed, clearCategory: trimmed.isNotEmpty);
    return _loadFirstPage();
  }

  Future<void> selectCategory(String? slug) {
    _debounce?.cancel();
    if (slug == state.categorySlug && state.query.isEmpty) {
      return Future<void>.value();
    }
    state = state.copyWith(
      query: '',
      categorySlug: slug,
      clearCategory: slug == null,
    );
    return _loadFirstPage();
  }

  Future<void> setSort(ProductSort sort) {
    if (sort == state.sort) return Future<void>.value();
    state = state.copyWith(sort: sort);
    return _loadFirstPage();
  }

  Future<void> loadMore({bool retry = false}) async {
    if (state.status != ListStatus.success ||
        state.isLoadingMore ||
        !state.hasMore ||
        (state.loadMoreFailed && !retry)) {
      return;
    }
    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetch(skip: _nextSkip);
      if (requestId != _requestId) return;
      _nextSkip += page.products.length;
      final seen = state.products.map((p) => p.id).toSet();
      final fresh = page.products.where((p) => seen.add(p.id)).toList();
      state = state.copyWith(
        products: [...state.products, ...fresh],
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } on Failure {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    _nextSkip = 0;
    state = state.copyWith(
      status: ListStatus.loading,
      products: const [],
      hasMore: true,
      isLoadingMore: false,
      loadMoreFailed: false,
      clearFailure: true,
    );
    try {
      final page = await _fetch(skip: 0);
      // A newer request superseded this one, so its result is stale.
      if (requestId != _requestId) return;
      _nextSkip = page.products.length;
      final unique = <int>{};
      final products = page.products.where((p) => unique.add(p.id)).toList();
      state = state.copyWith(
        status: products.isEmpty ? ListStatus.empty : ListStatus.success,
        products: products,
        hasMore: page.hasMore,
      );
    } on Failure catch (failure) {
      if (requestId != _requestId) return;
      state = state.copyWith(status: ListStatus.failure, failure: failure);
    }
  }

  Future<ProductPage> _fetch({required int skip}) =>
      ref.read(getProductsPageUseCaseProvider)(
        query: state.query,
        categorySlug: state.categorySlug,
        sort: state.sort,
        skip: skip,
        limit: pageSize,
      );
}

final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);
