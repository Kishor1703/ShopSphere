import '../../domain/entities/cart_item.dart';

extension CartItemJson on CartItem {
  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'thumbnail': thumbnail,
        'price': price,
        'discountPercentage': discountPercentage,
        'quantity': quantity,
        'stock': stock,
      };

  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
        productId: (json['productId'] as num).toInt(),
        title: json['title'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        discountPercentage:
            (json['discountPercentage'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num).toInt(),
        stock: (json['stock'] as num?)?.toInt() ?? 0,
      );
}
