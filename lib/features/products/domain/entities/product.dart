import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  final int rating;
  final String comment;
  final String reviewerName;
  final String? date;

  @override
  List<Object?> get props => [rating, comment, reviewerName, date];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    this.brand,
    this.images = const [],
    this.reviews = const [],
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String? brand;
  final String thumbnail;
  final List<String> images;
  final List<Review> reviews;

  bool get inStock => stock > 0;
  bool get hasDiscount => discountPercentage > 0;
  double get discountedPrice => price * (1 - discountPercentage / 100);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        price,
        discountPercentage,
        rating,
        stock,
        brand,
        thumbnail,
        images,
        reviews,
      ];
}

class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    this.isOffline = false,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final bool isOffline;

  /// True while the server still has items beyond this page.
  bool get hasMore => products.isNotEmpty && skip + products.length < total;

  @override
  List<Object?> get props => [products, total, skip, isOffline];
}

class Category extends Equatable {
  const Category({required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  List<Object?> get props => [slug, name];
}

/// Sort choices mapped to DummyJSON's `sortBy` / `order` query parameters.
enum ProductSort {
  featured('Featured', null, null),
  priceLowHigh('Price: low to high', 'price', 'asc'),
  priceHighLow('Price: high to low', 'price', 'desc'),
  rating('Top rated', 'rating', 'desc'),
  title('Title: A to Z', 'title', 'asc');

  const ProductSort(this.label, this.sortBy, this.order);

  final String label;
  final String? sortBy;
  final String? order;
}
