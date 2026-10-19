import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../datasources/product_cache.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote, {ProductCache? cache}) : _cache = cache;

  final ProductCache? _cache;
  bool _offline(Failure failure) =>
      failure.type == FailureType.network ||
      failure.type == FailureType.timeout;

  final ProductRemoteDataSource _remote;

  @override
  Future<ProductPage> getProducts({
    String query = '',
    String? categorySlug,
    ProductSort sort = ProductSort.featured,
    int skip = 0,
    int limit = 20,
  }) async {
    final cacheKey = _cache?.key(query, categorySlug, sort, skip, limit);
    try {
      final page = await _remote.getProducts(
        query: query,
        categorySlug: categorySlug,
        sort: sort,
        skip: skip,
        limit: limit,
      );
      // A cache write failure must not discard a successful network response.
      try {
        if (cacheKey != null) await _cache?.save(cacheKey, page);
      } catch (_) {}
      return page;
    } catch (e) {
      final failure = mapError(e);
      final cached = cacheKey == null ? null : _cache?.load(cacheKey);
      if (_offline(failure) && cached != null) return cached;
      throw failure;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      final categories = await _remote.getCategories();
      try {
        await _cache?.saveCategories(categories);
      } catch (_) {}
      return categories;
    } catch (e) {
      final failure = mapError(e);
      final cached = _cache?.loadCategories();
      if (_offline(failure) && cached != null) return cached;
      throw failure;
    }
  }

  @override
  Future<Product> getProduct(int id) async {
    try {
      return await _remote.getProduct(id);
    } catch (e) {
      final failure = mapError(e);
      final cached = _cache?.find(id);
      if (_offline(failure) && cached != null) return cached;
      throw failure;
    }
  }
}
