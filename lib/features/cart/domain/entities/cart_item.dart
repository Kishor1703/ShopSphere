import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product.dart';

double _toCents(double value) => (value * 100).round() / 100;

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.discountPercentage,
    required this.quantity,
    required this.stock,
  });

  factory CartItem.fromProduct(Product product, int quantity) => CartItem(
        productId: product.id,
        title: product.title,
        thumbnail: product.thumbnail,
        price: product.price,
        discountPercentage: product.discountPercentage,
        quantity: quantity,
        stock: product.stock,
      );

  final int productId;
  final String title;
  final String thumbnail;
  final double price;
  final double discountPercentage;
  final int quantity;
  final int stock;

  double get unitDiscountedPrice => price * (1 - discountPercentage / 100);

  /// List price multiplied by quantity.
  double get lineSubtotal => _toCents(price * quantity);

  /// Discount for the line, rounded to cents.
  double get lineDiscount =>
      _toCents(price * discountPercentage / 100 * quantity);

  double get lineTotal => _toCents(lineSubtotal - lineDiscount);

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        title: title,
        thumbnail: thumbnail,
        price: price,
        discountPercentage: discountPercentage,
        quantity: quantity ?? this.quantity,
        stock: stock,
      );

  @override
  List<Object?> get props =>
      [productId, title, thumbnail, price, discountPercentage, quantity, stock];
}

/// Pricing rules:
///   subtotal = sum(price x quantity)                 (list prices)
///   discount = sum(price x discount% x quantity)     (each line rounded to cents)
///   total    = subtotal - discount
class CartSummary extends Equatable {
  const CartSummary({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.itemCount,
  });

  factory CartSummary.fromItems(List<CartItem> items) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineSubtotal);
    final discount = items.fold<double>(0, (sum, i) => sum + i.lineDiscount);
    return CartSummary(
      subtotal: _toCents(subtotal),
      discount: _toCents(discount),
      total: _toCents(subtotal - discount),
      itemCount: items.fold<int>(0, (sum, i) => sum + i.quantity),
    );
  }

  final double subtotal;
  final double discount;
  final double total;
  final int itemCount;

  @override
  List<Object?> get props => [subtotal, discount, total, itemCount];
}
