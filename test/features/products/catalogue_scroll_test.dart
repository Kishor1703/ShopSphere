import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';
import 'package:shopsphere/features/products/presentation/providers/product_providers.dart';
import 'package:shopsphere/features/products/presentation/pages/home_page.dart';
import 'package:shopsphere/features/cart/presentation/providers/cart_providers.dart';
import '../../helpers/factories.dart';

class CatalogueRepository extends Mock implements ProductRepository {}

void main() {
  testWidgets(
      'scroll loads footer page, preserves offset and scrolls header away',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    registerFallbackValue(ProductSort.featured);
    final repository = CatalogueRepository();
    final pending = Completer<ProductPage>();
    final skips = <int>[];
    when(() => repository.getProducts(
          query: any(named: 'query'),
          categorySlug: any(named: 'categorySlug'),
          sort: any(named: 'sort'),
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
        )).thenAnswer((i) {
      final skip = i.namedArguments[#skip] as int;
      skips.add(skip);
      return skip == 0 ? Future.value(buildPage(total: 40)) : pending.future;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        categoriesProvider.overrideWith((ref) async => []),
        cartCountProvider.overrideWithValue(0),
      ],
      child: const MaterialApp(home: HomePage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final scroll =
        tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    final controller = scroll.controller!;
    controller.jumpTo(controller.position.maxScrollExtent - 150);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(skips, [0, 20]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('A little discovery, every day.').hitTestable(),
        findsNothing);
    final offset = controller.offset;
    pending.complete(buildPage(skip: 20, total: 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, offset);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(skips, [0, 20]);
    expect(find.text('You have seen everything'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
