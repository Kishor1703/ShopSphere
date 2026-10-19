import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const preferenceKey = 'appearance_theme';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(preferenceKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setString(preferenceKey, mode.name);
    if (!saved) throw StateError('Could not save appearance');
    state = mode;
  }
}
