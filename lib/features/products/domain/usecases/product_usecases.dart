import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsPageUseCase {
  const GetProductsPageUseCase(this._repository);
  final ProductRepository _repository;

  Future<ProductPage> call({
    String query = '',
    String? categorySlug,
    ProductSort sort = ProductSort.featured,
    int skip = 0,
    int limit = 20,
  }) =>
      _repository.getProducts(
        query: query,
        categorySlug: categorySlug,
        sort: sort,
        skip: skip,
        limit: limit,
      );
}

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);
  final ProductRepository _repository;

  Future<List<Category>> call() => _repository.getCategories();
}

class GetProductUseCase {
  const GetProductUseCase(this._repository);
  final ProductRepository _repository;

  Future<Product> call(int id) => _repository.getProduct(id);
}
