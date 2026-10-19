import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/di/providers.dart';
import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:shopsphere/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopsphere/features/products/presentation/providers/wishlist_provider.dart';
import 'package:shopsphere/features/products/data/datasources/product_cache.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_datasource.dart';
import 'package:shopsphere/features/products/data/models/product_model.dart';
import 'package:shopsphere/features/products/data/repositories/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/core/error/failure.dart';
import '../helpers/factories.dart';
import '../helpers/fixture_reader.dart';

class Remote extends Mock implements ProductRemoteDataSource {}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  ProviderContainer container(int user) => ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(user),
      ]);
  test('wishlist survives restart, removes favourites, and isolates users',
      () async {
    final first = container(1);
    await first.read(wishlistProvider.notifier).toggle(buildProduct());
    first.dispose();
    final second = container(1);
    final other = container(2);
    addTearDown(second.dispose);
    addTearDown(other.dispose);
    expect(second.read(wishlistProvider).single.id, 1);
    expect(other.read(wishlistProvider), isEmpty);
    await second.read(wishlistProvider.notifier).toggle(buildProduct());
    expect(second.read(wishlistProvider), isEmpty);
  });
  test(
      'offline cache matches query and pagination, and never masks server errors',
      () async {
    final remote = Remote();
    final cache = ProductCache(prefs);
    final repo = ProductRepositoryImpl(remote, cache: cache);
    when(() => remote.getProducts(
            query: '',
            categorySlug: null,
            sort: ProductSort.featured,
            skip: 0,
            limit: 20))
        .thenAnswer((_) async =>
            ProductPageModel.fromJson(fixtureJson('products_page.json')));
    final online = await repo.getProducts();
    expect(online.isOffline, isFalse);
    when(() => remote.getProducts(
        query: '',
        categorySlug: null,
        sort: ProductSort.featured,
        skip: 0,
        limit: 20)).thenThrow(connectionError());
    final offline = await repo.getProducts();
    expect(offline.isOffline, isTrue);
    expect(offline.products, online.products);
    expect(cache.load(cache.key('other', null, ProductSort.featured, 0, 20)),
        isNull);
    expect(
        cache.load(cache.key('', null, ProductSort.featured, 20, 20)), isNull);
    when(() => remote.getProducts(
        query: '',
        categorySlug: null,
        sort: ProductSort.featured,
        skip: 0,
        limit: 20)).thenThrow(statusError(500));
    await expectLater(repo.getProducts(), throwsA(isA<Failure>()));
  });
  testWidgets('Hindi labels render and language choice persists',
      (tester) async {
    final state = container(1);
    await state.read(localeProvider.notifier).setLanguage('hi');
    state.dispose();
    final restored = container(1);
    addTearDown(restored.dispose);
    expect(restored.read(localeProvider), const Locale('hi'));
    await tester.pumpWidget(MaterialApp(
      locale: restored.read(localeProvider),
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppMaterialDelegate(),
        AppWidgetsDelegate()
      ],
      home: Builder(
          builder: (context) =>
              Scaffold(body: Text(context.tr('Welcome back')))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('वापस स्वागत है'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
