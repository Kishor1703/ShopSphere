import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repositories.dart';
import '../datasources/cart_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local);

  final CartLocalDataSource _local;

  @override
  List<CartItem> loadCart(int userId) => _local.load(userId);

  @override
  Future<void> saveCart(int userId, List<CartItem> items) =>
      _local.save(userId, items);
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<void> placeOrder({
    required int userId,
    required List<CartItem> items,
  }) async {
    try {
      await _remote.submit(userId: userId, items: items);
    } catch (e) {
      throw mapError(e);
    }
  }
}
