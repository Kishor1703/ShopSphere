import '../../domain/entities/product.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.rating,
    required super.comment,
    required super.reviewerName,
    super.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String? ?? '',
        reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
        date: json['date'] as String?,
      );
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.price,
    required super.discountPercentage,
    required super.rating,
    required super.stock,
    required super.thumbnail,
    super.brand,
    super.images,
    super.reviews,
  });

  /// A missing or non-numeric `id` throws, which the repository reports as a
  /// parsing failure. Every other field has a safe default.
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        discountPercentage:
            (json['discountPercentage'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        brand: json['brand'] as String?,
        thumbnail: json['thumbnail'] as String? ?? '',
        images:
            (json['images'] as List<dynamic>?)?.whereType<String>().toList() ??
                const [],
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class ProductPageModel extends ProductPage {
  const ProductPageModel({
    required super.products,
    required super.total,
    required super.skip,
  });

  factory ProductPageModel.fromJson(Map<String, dynamic> json) =>
      ProductPageModel(
        products: (json['products'] as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toInt(),
        skip: (json['skip'] as num).toInt(),
      );
}

class CategoryModel extends Category {
  const CategoryModel({required super.slug, required super.name});

  /// DummyJSON returns either plain strings or `{slug, name, url}` objects
  /// depending on version, so both shapes are accepted.
  factory CategoryModel.fromJson(Object? json) {
    if (json is String) {
      return CategoryModel(slug: json, name: _titleCase(json));
    }
    final map = json! as Map<String, dynamic>;
    final slug = map['slug'] as String;
    return CategoryModel(
      slug: slug,
      name: map['name'] as String? ?? _titleCase(slug),
    );
  }

  static String _titleCase(String slug) => slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Shared representation for the offline catalogue and local favourites.
Map<String, dynamic> productToJson(Product product) => {
      'id': product.id,
      'title': product.title,
      'description': product.description,
      'category': product.category,
      'price': product.price,
      'discountPercentage': product.discountPercentage,
      'rating': product.rating,
      'stock': product.stock,
      'brand': product.brand,
      'thumbnail': product.thumbnail,
      'images': product.images,
      'reviews': [
        for (final review in product.reviews)
          {
            'rating': review.rating,
            'comment': review.comment,
            'reviewerName': review.reviewerName,
            'date': review.date,
          }
      ],
    };
