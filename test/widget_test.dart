import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/app.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/main.dart';

import 'helpers/factories.dart';

class StartupTokens extends InMemoryTokenStorage {
  bool fail = false;
  bool hang = false;

  @override
  Future<String?> readAccessToken() async {
    if (fail) throw PlatformException(code: 'storage_unavailable');
    if (hang) return Completer<String?>().future;
    return super.readAccessToken();
  }
}

void main() {
  testWidgets('fresh install leaves splash and shows login', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(StartupTokens())],
      child: const ShopSphereApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage failure shows retry and recovers to login', (tester) async {
    final tokens = StartupTokens()..fail = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(tokens)],
      child: const ShopSphereApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Could not start ShopSphere'), findsOneWidget);
    tokens.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unresponsive storage times out instead of spinning forever',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(StartupTokens()..hang = true),
      ],
      child: const ShopSphereApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('Could not start ShopSphere'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('bootstrap renders before preference initialization completes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ShopSphereBootstrap());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 16));
  });
}
