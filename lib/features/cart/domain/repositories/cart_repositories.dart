import '../entities/cart_item.dart';

abstract class CartRepository {
  List<CartItem> loadCart(int userId);
  Future<void> saveCart(int userId, List<CartItem> items);
}

abstract class OrderRepository {
  /// Submits a simulated order. Throws a `Failure` on error.
  Future<void> placeOrder({
    required int userId,
    required List<CartItem> items,
  });
}
