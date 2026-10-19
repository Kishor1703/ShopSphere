import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';

import '../../helpers/fixture_reader.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('parses every field of a full product', () {
      final product = ProductModel.fromJson(fixtureJson('product.json'));

      expect(product.id, 144);
      expect(product.title, 'Apple iPhone 5s');
      expect(product.price, 199.99);
      expect(product.discountPercentage, 10.5);
      expect(product.brand, 'Apple');
      expect(product.images, hasLength(2));
      expect(product.reviews.single.reviewerName, 'Eleanor Collins');
      expect(product.inStock, isTrue);
    });

    test('tolerates missing optional fields', () {
      final product = ProductModel.fromJson(fixtureJson('product_no_brand.json'));

      expect(product.brand, isNull);
      expect(product.images, isEmpty);
      expect(product.reviews, isEmpty);
      expect(product.discountPercentage, 0);
      expect(product.inStock, isFalse);
    });

    test('throws when the id is missing', () {
      expect(
        () => ProductModel.fromJson(const {'title': 'No id'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('computes the discounted price', () {
      final product = ProductModel.fromJson(fixtureJson('product.json'));
      expect(product.discountedPrice, closeTo(178.99, 0.01));
    });
  });

  group('ProductPageModel.fromJson', () {
    test('parses a page and reports that more items remain', () {
      final page = ProductPageModel.fromJson(fixtureJson('products_page.json'));

      expect(page.products, hasLength(2));
      expect(page.total, 194);
      expect(page.hasMore, isTrue);
    });
  });

  group('CategoryModel.fromJson', () {
    test('accepts both plain strings and objects', () {
      final fromString = CategoryModel.fromJson('home-decoration');
      final fromObject = CategoryModel.fromJson(
        const {'slug': 'beauty', 'name': 'Beauty', 'url': 'x'},
      );

      expect(fromString.name, 'Home Decoration');
      expect(fromObject.slug, 'beauty');
    });
  });
}
