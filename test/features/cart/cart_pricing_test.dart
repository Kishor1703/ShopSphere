import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/cart/domain/entities/cart_item.dart';

import '../../helpers/factories.dart';

void main() {
  test('an empty cart totals zero', () {
    final summary = CartSummary.fromItems(const []);

    expect(summary.subtotal, 0);
    expect(summary.discount, 0);
    expect(summary.total, 0);
    expect(summary.itemCount, 0);
  });

  test('calculates subtotal, discount and total from list prices', () {
    final items = [
      CartItem.fromProduct(buildProduct(id: 1, price: 100, discount: 10), 2),
      CartItem.fromProduct(buildProduct(id: 2, price: 50), 1),
    ];

    final summary = CartSummary.fromItems(items);

    expect(summary.subtotal, 250);
    expect(summary.discount, 20);
    expect(summary.total, 230);
    expect(summary.itemCount, 3);
  });

  test('rounds each line discount to cents', () {
    final item = CartItem.fromProduct(
      buildProduct(price: 19.99, discount: 15),
      3,
    );

    final summary = CartSummary.fromItems([item]);

    expect(summary.subtotal, closeTo(59.97, 0.001));
    expect(summary.discount, closeTo(9.00, 0.001));
    expect(summary.total, closeTo(50.97, 0.001));
  });
}
