import 'package:dio/dio.dart';

import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ProductPageModel> getProducts({
    required String query,
    required String? categorySlug,
    required ProductSort sort,
    required int skip,
    required int limit,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'skip': skip};
    if (sort.sortBy != null) {
      params['sortBy'] = sort.sortBy;
      params['order'] = sort.order;
    }

    final trimmed = query.trim();
    final String path;
    if (trimmed.isNotEmpty) {
      path = '/products/search';
      params['q'] = trimmed;
    } else if (categorySlug != null) {
      path = '/products/category/$categorySlug';
    } else {
      path = '/products';
    }

    final response =
        await _dio.get<Map<String, dynamic>>(path, queryParameters: params);
    return ProductPageModel.fromJson(response.data!);
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get<List<dynamic>>('/products/categories');
    return response.data!.map(CategoryModel.fromJson).toList();
  }

  Future<ProductModel> getProduct(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/products/$id');
    return ProductModel.fromJson(response.data!);
  }
}
