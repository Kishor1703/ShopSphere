import '../../../../core/error/failure.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repositories.dart';

class PlaceOrderUseCase {
  const PlaceOrderUseCase(this._repository);
  final OrderRepository _repository;

  Future<void> call({required int userId, required List<CartItem> items}) {
    if (items.isEmpty) {
      throw const Failure(FailureType.badRequest, 'Your cart is empty.');
    }
    return _repository.placeOrder(userId: userId, items: items);
  }
}
