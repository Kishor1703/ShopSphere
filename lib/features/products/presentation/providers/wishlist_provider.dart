import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/product_model.dart';
import '../../domain/entities/product.dart';

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<Product>>(WishlistNotifier.new);

class WishlistNotifier extends Notifier<List<Product>> {
  String? _key;
  @override
  List<Product> build() {
    final user = ref.watch(currentUserIdProvider);
    _key = user == null ? null : 'wishlist_user_$user';
    if (_key == null) return [];
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key!) ?? '[]';
      return (jsonDecode(raw) as List)
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggle(Product product) async {
    final key = _key;
    if (key == null) return;
    final previous = state;
    final next = state.any((p) => p.id == product.id)
        ? state.where((p) => p.id != product.id).toList()
        : [...state, product];
    state = next;
    try {
      final saved = await ref
          .read(sharedPreferencesProvider)
          .setString(key, jsonEncode(next.map(productToJson).toList()));
      if (!saved) throw StateError('Could not save favourites');
    } catch (_) {
      if (_key == key && identical(state, next)) state = previous;
      rethrow;
    }
  }
}
