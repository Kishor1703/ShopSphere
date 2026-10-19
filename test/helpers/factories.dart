import 'package:dio/dio.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';

Product buildProduct({
  int id = 1,
  double price = 100,
  double discount = 0,
  int stock = 10,
  String? brand,
}) =>
    Product(
      id: id,
      title: 'Product $id',
      description: 'Description $id',
      category: 'test',
      price: price,
      discountPercentage: discount,
      rating: 4,
      stock: stock,
      thumbnail: 'https://example.com/$id.png',
      brand: brand,
    );

ProductPage buildPage({int count = 20, int skip = 0, int total = 100}) =>
    ProductPage(
      products: List.generate(count, (i) => buildProduct(id: skip + i + 1)),
      total: total,
      skip: skip,
    );

DioException statusError(int status) {
  final options = RequestOptions(path: '/test');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

DioException connectionError() => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

class InMemoryTokenStorage implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }
}
