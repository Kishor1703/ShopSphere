import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopsphere/features/cart/presentation/providers/cart_providers.dart';

import '../../helpers/factories.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer({int? userId = 1}) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(userId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('adds a new product to the cart', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);

    final result = notifier.add(buildProduct(id: 5), 2);

    expect(result, AddToCartResult.added);
    expect(container.read(cartProvider).single.quantity, 2);
    expect(container.read(cartCountProvider), 2);
  });

  test('merges repeated adds into one line', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);

    notifier.add(buildProduct(id: 5), 1);
    notifier.add(buildProduct(id: 5), 2);

    expect(container.read(cartProvider), hasLength(1));
    expect(container.read(cartProvider).single.quantity, 3);
  });

  test('limits quantity to the available stock', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);
    final product = buildProduct(id: 5, stock: 3);

    notifier.add(product, 2);
    final result = notifier.add(product, 5);

    expect(result, AddToCartResult.limitedByStock);
    expect(container.read(cartProvider).single.quantity, 3);
  });

  test('refuses out-of-stock products and invalid quantities', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);

    expect(
      notifier.add(buildProduct(stock: 0), 1),
      AddToCartResult.outOfStock,
    );
    expect(
      notifier.add(buildProduct(id: 2), 0),
      AddToCartResult.invalidQuantity,
    );
    expect(container.read(cartProvider), isEmpty);
  });

  test('quantity never drops below one or exceeds stock', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);
    notifier.add(buildProduct(id: 5, stock: 2), 1);

    notifier.decrement(5);
    expect(container.read(cartProvider).single.quantity, 1);

    notifier.setQuantity(5, 0);
    notifier.setQuantity(5, -3);
    expect(container.read(cartProvider).single.quantity, 1);

    notifier.increment(5);
    notifier.increment(5);
    expect(container.read(cartProvider).single.quantity, 2);
  });

  test('removes an item', () {
    final container = makeContainer();
    final notifier = container.read(cartProvider.notifier);
    notifier.add(buildProduct(id: 1), 1);
    notifier.add(buildProduct(id: 2), 1);

    notifier.remove(1);

    expect(container.read(cartProvider).map((i) => i.productId), [2]);
  });

  test('restores the cart after a restart', () async {
    final first = makeContainer();
    first.read(cartProvider.notifier).add(buildProduct(id: 9, price: 20), 3);
    await pumpEventQueue();

    final restarted = makeContainer();

    final restored = restarted.read(cartProvider);
    expect(restored.single.productId, 9);
    expect(restored.single.quantity, 3);
  });

  test('keeps carts separate per user', () async {
    final alice = makeContainer(userId: 1);
    alice.read(cartProvider.notifier).add(buildProduct(id: 9), 1);
    await pumpEventQueue();

    final bob = makeContainer(userId: 2);

    expect(bob.read(cartProvider), isEmpty);
  });

  test('ignores corrupted stored data', () {
    SharedPreferences.setMockInitialValues({'cart_user_1': 'not json'});
    final container = makeContainer();

    expect(container.read(cartProvider), isEmpty);
  });
}
