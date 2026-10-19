import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/cart/presentation/pages/order_success_page.dart';
import 'features/products/presentation/pages/home_page.dart';
import 'features/products/presentation/pages/wishlist_page.dart';
import 'features/products/presentation/pages/product_detail_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ValueNotifier<AuthStatus>(ref.read(authProvider).status);
  ref.listen(authProvider.select((s) => s.status), (_, next) {
    authStatus.value = next;
  });
  ref.onDispose(authStatus.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStatus,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final location = state.matchedLocation;
      switch (status) {
        case AuthStatus.unknown:
        case AuthStatus.error:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return location == '/login' ? null : '/login';
        case AuthStatus.authenticated:
          return (location == '/splash' || location == '/login')
              ? '/home'
              : null;
      }
    },
    routes: [
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistPage()),
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailPage(
          productId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        path: '/order-success',
        builder: (_, __) => const OrderSuccessPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomePage())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (_, __) => const CartPage())
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfilePage()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
