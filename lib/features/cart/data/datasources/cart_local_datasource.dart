import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

class CartLocalDataSource {
  CartLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  String _key(int userId) => 'cart_user_$userId';

  /// Returns an empty cart when nothing is stored or the data is corrupted.
  List<CartItem> load(int userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CartItemJson.fromJson(e as Map<String, dynamic>))
          .where((i) => i.quantity > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(int userId, List<CartItem> items) async {
    await _prefs.setString(
      _key(userId),
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }
}
