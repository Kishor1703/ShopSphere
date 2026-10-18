import 'package:dio/dio.dart';

import '../../domain/entities/cart_item.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> submit({required int userId, required List<CartItem> items}) {
    return _dio.post<Map<String, dynamic>>(
      '/carts/add',
      data: {
        'userId': userId,
        'products': [
          for (final item in items)
            {'id': item.productId, 'quantity': item.quantity},
        ],
      },
    );
  }
}
