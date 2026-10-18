import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<ProductPage> getProducts({
    String query = '',
    String? categorySlug,
    ProductSort sort = ProductSort.featured,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      return await _remote.getProducts(
        query: query,
        categorySlug: categorySlug,
        sort: sort,
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      return await _remote.getCategories();
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<Product> getProduct(int id) async {
    try {
      return await _remote.getProduct(id);
    } catch (e) {
      throw mapError(e);
    }
  }
}
