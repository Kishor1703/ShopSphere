import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopsphere/features/cart/domain/entities/cart_item.dart';
import 'package:shopsphere/features/cart/domain/repositories/cart_repositories.dart';
import 'package:shopsphere/features/cart/presentation/providers/cart_providers.dart';

import '../../helpers/factories.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository orders;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(<CartItem>[]));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    orders = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(7),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add(buildProduct(id: 3, price: 40), 2);
  });

  When<Future<void>> stubPlaceOrder() => when(
        () => orders.placeOrder(
          userId: any(named: 'userId'),
          items: any(named: 'items'),
        ),
      );

  test('success clears the cart and records the order totals', () async {
    stubPlaceOrder().thenAnswer((_) async {});

    final ok = await container.read(checkoutProvider.notifier).placeOrder();

    expect(ok, isTrue);
    expect(container.read(cartProvider), isEmpty);
    expect(container.read(checkoutProvider).lastOrder?.total, 80);
    verify(
      () => orders.placeOrder(userId: 7, items: any(named: 'items')),
    ).called(1);
  });

  test('failure keeps the cart and exposes a friendly message', () async {
    stubPlaceOrder().thenThrow(
      const Failure(FailureType.server, 'Our server ran into a problem.'),
    );

    final ok = await container.read(checkoutProvider.notifier).placeOrder();

    expect(ok, isFalse);
    expect(container.read(cartProvider), hasLength(1));
    expect(container.read(checkoutProvider).errorMessage, isNotNull);
    expect(container.read(checkoutProvider).isSubmitting, isFalse);
  });

  test('a second tap while submitting is ignored', () async {
    final pending = Completer<void>();
    stubPlaceOrder().thenAnswer((_) => pending.future);
    final notifier = container.read(checkoutProvider.notifier);

    final first = notifier.placeOrder();
    final second = await notifier.placeOrder();
    pending.complete();
    await first;

    expect(second, isFalse);
    verify(
      () => orders.placeOrder(
        userId: any(named: 'userId'),
        items: any(named: 'items'),
      ),
    ).called(1);
  });

  test('can retry successfully after a failure', () async {
    stubPlaceOrder().thenThrow(const Failure(FailureType.network, 'Offline'));
    final notifier = container.read(checkoutProvider.notifier);
    await notifier.placeOrder();

    stubPlaceOrder().thenAnswer((_) async {});
    final ok = await notifier.placeOrder();

    expect(ok, isTrue);
    expect(container.read(cartProvider), isEmpty);
  });
}
