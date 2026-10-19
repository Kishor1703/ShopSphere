import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class ProductCache {
  ProductCache(this.preferences);
  final SharedPreferences preferences;
  static const _key = 'catalogue_cache_v1';

  Map<String, dynamic> _read() {
    try {
      return jsonDecode(preferences.getString(_key) ?? '{}')
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String key(String query, String? category, ProductSort sort, int skip,
          int limit) =>
      jsonEncode([query.trim(), category, sort.name, skip, limit]);

  Future<void> save(String key, ProductPage page) async {
    final pages = _read()..remove(key);
    pages[key] = {
      'products': page.products.map(productToJson).toList(),
      'total': page.total,
      'skip': page.skip
    };
    while (pages.length > 30) {
      pages.remove(pages.keys.first);
    }
    await preferences.setString(_key, jsonEncode(pages));
  }

  ProductPage? load(String key) {
    try {
      final raw = _read()[key];
      if (raw == null) return null;
      final page = ProductPageModel.fromJson(raw as Map<String, dynamic>);
      return ProductPage(
          products: page.products,
          total: page.total,
          skip: page.skip,
          isOffline: true);
    } catch (_) {
      return null;
    }
  }

  Product? find(int id) {
    for (final key in _read().keys.toList().reversed) {
      for (final product in load(key)?.products ?? <Product>[]) {
        if (product.id == id) return product;
      }
    }
    return null;
  }

  Future<bool> saveCategories(List<Category> categories) =>
      preferences.setString(
        'catalogue_categories_v1',
        jsonEncode([
          for (final c in categories) {'slug': c.slug, 'name': c.name}
        ]),
      );

  List<Category>? loadCategories() {
    try {
      final raw = preferences.getString('catalogue_categories_v1');
      return raw == null
          ? null
          : (jsonDecode(raw) as List).map(CategoryModel.fromJson).toList();
    } catch (_) {
      return null;
    }
  }
}
