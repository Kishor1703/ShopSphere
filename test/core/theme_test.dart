import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/app.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/theme/theme_provider.dart';

import '../helpers/factories.dart';

void main() {
  test('theme follows system by default and restores saved choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer createContainer() => ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ]);
    final first = createContainer();
    expect(first.read(themeModeProvider), ThemeMode.system);
    await first.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    first.dispose();
    final restored = createContainer();
    addTearDown(restored.dispose);
    expect(restored.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('login toggle changes both themes without losing input',
      (tester) async {
    SharedPreferences.setMockInitialValues({'appearance_theme': 'light'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      ],
      child: const ShopSphereApp(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(
        Theme.of(tester.element(find.byType(TextFormField).first)).brightness,
        Brightness.dark);
    expect(find.text('emilys'), findsOneWidget);
    expect(prefs.getString('appearance_theme'), 'dark');
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(
        Theme.of(tester.element(find.byType(TextFormField).first)).brightness,
        Brightness.light);
    expect(prefs.getString('appearance_theme'), 'light');
    expect(tester.takeException(), isNull);
  });
}
