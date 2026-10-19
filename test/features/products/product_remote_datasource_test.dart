import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_datasource.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import '../../helpers/fixture_reader.dart';

void main() {
  test('sends limit and skip for catalogue, search and category endpoints',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(
          requestOptions: options, data: fixtureJson('products_page.json')));
    }));
    final source = ProductRemoteDataSource(dio);
    await source.getProducts(
        query: '',
        categorySlug: null,
        sort: ProductSort.featured,
        skip: 20,
        limit: 20);
    await source.getProducts(
        query: 'phone',
        categorySlug: null,
        sort: ProductSort.featured,
        skip: 40,
        limit: 20);
    await source.getProducts(
        query: '',
        categorySlug: 'beauty',
        sort: ProductSort.featured,
        skip: 60,
        limit: 20);
    expect(requests.map((r) => r.path),
        ['/products', '/products/search', '/products/category/beauty']);
    expect(requests.map((r) => r.queryParameters['limit']), [20, 20, 20]);
    expect(requests.map((r) => r.queryParameters['skip']), [20, 40, 60]);
    expect(requests[1].queryParameters['q'], 'phone');
  });
}
