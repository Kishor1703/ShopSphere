import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_datasource.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';
import 'package:shopsphere/features/products/data/repositories/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

import '../../helpers/factories.dart';
import '../../helpers/fixture_reader.dart';

class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource {}

void main() {
  late MockProductRemoteDataSource remote;
  late ProductRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(ProductSort.featured));

  setUp(() {
    remote = MockProductRemoteDataSource();
    repository = ProductRepositoryImpl(remote);
  });

  When<Future<ProductPageModel>> stubGetProducts() => when(
        () => remote.getProducts(
          query: any(named: 'query'),
          categorySlug: any(named: 'categorySlug'),
          sort: any(named: 'sort'),
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
        ),
      );

  group('getProducts', () {
    test('returns the page on success', () async {
      final page = ProductPageModel.fromJson(fixtureJson('products_page.json'));
      stubGetProducts().thenAnswer((_) async => page);

      final result = await repository.getProducts();

      expect(result.products, hasLength(2));
    });

    test('maps a 500 response to a server failure', () async {
      stubGetProducts().thenThrow(statusError(500));

      expect(
        repository.getProducts(),
        throwsA(
          isA<Failure>().having((f) => f.type, 'type', FailureType.server),
        ),
      );
    });

    test('maps a connection error to a network failure', () async {
      stubGetProducts().thenThrow(connectionError());

      expect(
        repository.getProducts(),
        throwsA(
          isA<Failure>().having((f) => f.type, 'type', FailureType.network),
        ),
      );
    });

    test('maps unreadable data to a parsing failure', () async {
      stubGetProducts().thenThrow(const FormatException('bad json'));

      expect(
        repository.getProducts(),
        throwsA(
          isA<Failure>().having((f) => f.type, 'type', FailureType.parsing),
        ),
      );
    });

    test('returns an empty page for a search with no results', () async {
      stubGetProducts().thenAnswer(
        (_) async => const ProductPageModel(products: [], total: 0, skip: 0),
      );

      final result = await repository.getProducts(query: 'zzzz');

      expect(result.products, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });

  group('getProduct', () {
    test('maps a 404 to a notFound failure', () async {
      when(() => remote.getProduct(9999)).thenThrow(statusError(404));

      expect(
        repository.getProduct(9999),
        throwsA(
          isA<Failure>().having((f) => f.type, 'type', FailureType.notFound),
        ),
      );
    });
  });
}
