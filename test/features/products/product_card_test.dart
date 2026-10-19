import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/formatters.dart';
import 'package:shopsphere/core/widgets/rating_badge.dart';
import 'package:shopsphere/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopsphere/features/products/presentation/widgets/product_card.dart';
import 'package:shopsphere/features/products/presentation/widgets/wishlist_button.dart';
import '../../helpers/factories.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('product details render in ${brightness.name} theme', (tester) async {
      final product = buildProduct(discount: 10);
      var opened = false;
      await tester.pumpWidget(ProviderScope(
        overrides: [currentUserIdProvider.overrideWithValue(null)],
        child: MaterialApp(
          theme: buildAppTheme(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 290,
                child: ProductCard(product: product, onTap: () => opened = true),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text(product.title).hitTestable(), findsOneWidget);
      expect(find.text(formatPrice(product.discountedPrice)).hitTestable(), findsOneWidget);
      expect(find.text(formatPrice(product.price)).hitTestable(), findsOneWidget);
      expect(find.byType(RatingBadge), findsOneWidget);
      expect(find.byType(WishlistButton), findsOneWidget);
      await tester.tap(find.text(product.title));
      expect(opened, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}