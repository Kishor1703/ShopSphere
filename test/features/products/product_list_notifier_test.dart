import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';
import 'package:shopsphere/features/products/presentation/providers/product_providers.dart';

import '../../helpers/factories.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;

  setUpAll(() => registerFallbackValue(ProductSort.featured));
  setUp(() => repository = MockProductRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubPages(Future<ProductPage> Function(Invocation invocation) answer) {
    when(
      () => repository.getProducts(
        query: any(named: 'query'),
        categorySlug: any(named: 'categorySlug'),
        sort: any(named: 'sort'),
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(answer);
  }

  int skipOf(Invocation i) => i.namedArguments[#skip] as int;

  test('moves from loading to success on the first page', () async {
    stubPages((i) async => buildPage(total: 45));
    final container = makeContainer();
    final statuses = <ListStatus>[];
    container.listen(productListProvider, (_, next) => statuses.add(next.status));

    await container.read(productListProvider.notifier).loadInitial();

    expect(statuses, [ListStatus.loading, ListStatus.success]);
    expect(container.read(productListProvider).products, hasLength(20));
    expect(container.read(productListProvider).hasMore, isTrue);
  });

  test('reports empty when the server returns no products', () async {
    stubPages((i) async => const ProductPage(products: [], total: 0, skip: 0));
    final container = makeContainer();

    await container.read(productListProvider.notifier).loadInitial();

    expect(container.read(productListProvider).status, ListStatus.empty);
  });

  test('recovers from a failure when retried', () async {
    var attempts = 0;
    stubPages((i) async {
      attempts++;
      if (attempts == 1) {
        throw const Failure(FailureType.server, 'Server problem');
      }
      return buildPage(count: 5, total: 5);
    });
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);

    await notifier.loadInitial();
    expect(container.read(productListProvider).status, ListStatus.failure);
    expect(container.read(productListProvider).failure?.message, 'Server problem');

    await notifier.refresh();
    expect(container.read(productListProvider).status, ListStatus.success);
    expect(container.read(productListProvider).failure, isNull);
  });

  test('appends the next page and skips duplicate products', () async {
    stubPages((i) async {
      final skip = skipOf(i);
      // The second page repeats product 20 to simulate overlap.
      return skip == 0
          ? buildPage(total: 40)
          : buildPage(skip: 19, total: 40);
    });
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);

    await notifier.loadInitial();
    await notifier.loadMore();

    final ids = container.read(productListProvider).products.map((p) => p.id);
    expect(ids.toSet().length, ids.length);
    expect(ids.length, 39);
  });

  test('does not send a second request while one is in flight', () async {
    final pending = Completer<ProductPage>();
    stubPages((i) => skipOf(i) == 0 ? Future.value(buildPage()) : pending.future);
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);
    await notifier.loadInitial();

    final first = notifier.loadMore();
    final second = notifier.loadMore();
    pending.complete(buildPage(skip: 20));
    await Future.wait([first, second]);

    verify(
      () => repository.getProducts(
        query: any(named: 'query'),
        categorySlug: any(named: 'categorySlug'),
        sort: any(named: 'sort'),
        skip: 20,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('stops requesting once every product has been loaded', () async {
    stubPages((i) async => skipOf(i) == 0
        ? buildPage(total: 25)
        : buildPage(count: 5, skip: 20, total: 25));
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);

    await notifier.loadInitial();
    await notifier.loadMore();
    await notifier.loadMore();

    expect(container.read(productListProvider).hasMore, isFalse);
    verify(
      () => repository.getProducts(
        query: any(named: 'query'),
        categorySlug: any(named: 'categorySlug'),
        sort: any(named: 'sort'),
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
      ),
    ).called(2);
  });

  test('a failed load-more keeps the list and does not retry on its own', () async {
    var calls = 0;
    stubPages((i) async {
      calls++;
      if (skipOf(i) == 0) return buildPage();
      throw const Failure(FailureType.network, 'Offline');
    });
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);
    await notifier.loadInitial();

    await notifier.loadMore();
    await notifier.loadMore();

    final state = container.read(productListProvider);
    expect(state.products, hasLength(20));
    expect(state.loadMoreFailed, isTrue);
    expect(calls, 2);
  });

  test('ignores results of a search that was superseded', () async {
    final slow = Completer<ProductPage>();
    when(
      () => repository.getProducts(
        query: any(named: 'query'),
        categorySlug: any(named: 'categorySlug'),
        sort: any(named: 'sort'),
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((i) {
      final query = i.namedArguments[#query] as String;
      return query == 'old'
          ? slow.future
          : Future.value(buildPage(count: 1, total: 1, skip: 98));
    });
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);

    final oldSearch = notifier.search('old');
    final newSearch = notifier.search('new');
    await newSearch;
    slow.complete(buildPage(count: 3, total: 3));
    await oldSearch;

    final state = container.read(productListProvider);
    expect(state.query, 'new');
    expect(state.products.map((p) => p.id), [99]);
  });

  test('choosing a category clears the search and resets the list', () async {
    stubPages((i) async => buildPage(count: 3, total: 3));
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);
    await notifier.search('phone');

    await notifier.selectCategory('beauty');

    final state = container.read(productListProvider);
    expect(state.query, isEmpty);
    expect(state.categorySlug, 'beauty');
    verify(
      () => repository.getProducts(
        query: '',
        categorySlug: 'beauty',
        sort: any(named: 'sort'),
        skip: 0,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('changing the sort order reloads from the first page', () async {
    stubPages((i) async => buildPage(count: 3, total: 3));
    final container = makeContainer();
    final notifier = container.read(productListProvider.notifier);
    await notifier.loadInitial();

    await notifier.setSort(ProductSort.priceHighLow);

    expect(container.read(productListProvider).sort, ProductSort.priceHighLow);
    verify(
      () => repository.getProducts(
        query: any(named: 'query'),
        categorySlug: any(named: 'categorySlug'),
        sort: ProductSort.priceHighLow,
        skip: 0,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });
}
