import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/cart_repositories_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repositories.dart';
import '../../domain/usecases/place_order_usecase.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(
    CartLocalDataSource(ref.watch(sharedPreferencesProvider)),
  ),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(OrderRemoteDataSource(ref.watch(dioProvider))),
);

final placeOrderUseCaseProvider = Provider(
  (ref) => PlaceOrderUseCase(ref.watch(orderRepositoryProvider)),
);

enum AddToCartResult { added, limitedByStock, outOfStock, invalidQuantity }

/// Local cart; the single source of truth until an order succeeds.
/// Stored per user, and reloaded when the signed-in user changes.
class CartNotifier extends Notifier<List<CartItem>> {
  int? _userId;

  @override
  List<CartItem> build() {
    _userId = ref.watch(currentUserIdProvider);
    final id = _userId;
    if (id == null) return const [];
    return ref.read(cartRepositoryProvider).loadCart(id);
  }

  AddToCartResult add(Product product, int quantity) {
    if (!product.inStock) return AddToCartResult.outOfStock;
    if (quantity < 1) return AddToCartResult.invalidQuantity;

    final index = state.indexWhere((i) => i.productId == product.id);
    final existing = index >= 0 ? state[index].quantity : 0;
    final desired = existing + quantity;
    final clamped = desired > product.stock ? product.stock : desired;
    final result = desired > product.stock
        ? AddToCartResult.limitedByStock
        : AddToCartResult.added;

    if (index >= 0) {
      if (clamped == existing) return AddToCartResult.limitedByStock;
      _update([
        for (var i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(quantity: clamped) else state[i],
      ]);
    } else {
      _update([...state, CartItem.fromProduct(product, clamped)]);
    }
    return result;
  }

  /// Ignores values below 1 or above the item's stock.
  void setQuantity(int productId, int quantity) {
    final index = state.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    final item = state[index];
    if (quantity < 1 || quantity > item.stock || quantity == item.quantity) {
      return;
    }
    _update([
      for (final i in state)
        if (i.productId == productId) i.copyWith(quantity: quantity) else i,
    ]);
  }

  void increment(int productId) {
    final item = state.where((i) => i.productId == productId).firstOrNull;
    if (item != null) setQuantity(productId, item.quantity + 1);
  }

  void decrement(int productId) {
    final item = state.where((i) => i.productId == productId).firstOrNull;
    if (item != null) setQuantity(productId, item.quantity - 1);
  }

  void remove(int productId) =>
      _update(state.where((i) => i.productId != productId).toList());

  void clear() => _update(const []);

  void _update(List<CartItem> items) {
    state = items;
    final id = _userId;
    if (id != null) {
      unawaited(ref.read(cartRepositoryProvider).saveCart(id, items));
    }
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartSummaryProvider = Provider<CartSummary>(
  (ref) => CartSummary.fromItems(ref.watch(cartProvider)),
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartSummaryProvider).itemCount,
);

class CheckoutState extends Equatable {
  const CheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastOrder,
  });

  final bool isSubmitting;
  final String? errorMessage;

  /// Totals of the most recent successful order, for the confirmation page.
  final CartSummary? lastOrder;

  @override
  List<Object?> get props => [isSubmitting, errorMessage, lastOrder];
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Returns true only when the order succeeded. The cart is cleared on
  /// success and left untouched on failure. Re-entrant calls are ignored.
  Future<bool> placeOrder() async {
    if (state.isSubmitting) return false;
    final items = ref.read(cartProvider);
    final userId = ref.read(currentUserIdProvider);
    if (items.isEmpty || userId == null) return false;

    final summary = CartSummary.fromItems(items);
    state = CheckoutState(isSubmitting: true, lastOrder: state.lastOrder);
    try {
      await ref.read(placeOrderUseCaseProvider)(userId: userId, items: items);
      ref.read(cartProvider.notifier).clear();
      state = CheckoutState(lastOrder: summary);
      return true;
    } on Failure catch (failure) {
      state = CheckoutState(
        errorMessage: failure.message,
        lastOrder: state.lastOrder,
      );
      return false;
    }
  }

  void dismissError() {
    state = CheckoutState(lastOrder: state.lastOrder);
  }
}

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
