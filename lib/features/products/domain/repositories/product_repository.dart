import '../entities/product.dart';

abstract class ProductRepository {
  /// When [query] is not blank it takes priority over [categorySlug].
  Future<ProductPage> getProducts({
    String query = '',
    String? categorySlug,
    ProductSort sort = ProductSort.featured,
    int skip = 0,
    int limit = 20,
  });

  Future<List<Category>> getCategories();

  Future<Product> getProduct(int id);
}
