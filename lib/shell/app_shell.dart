import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/responsive.dart';
import '../core/widgets/scroll_navigation_scaffold.dart';
import '../features/cart/presentation/providers/cart_providers.dart';

/// Bottom navigation on compact screens, navigation rail on larger ones.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);

    Widget cartIcon(IconData icon) => Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(icon),
        );

    final destinations = <({String label, Widget icon, Widget selectedIcon})>[
      (
        label: context.tr('Shop'),
        icon: const Icon(Icons.storefront_outlined),
        selectedIcon: const Icon(Icons.storefront),
      ),
      (
        label: context.tr('Cart'),
        icon: cartIcon(Icons.shopping_cart_outlined),
        selectedIcon: cartIcon(Icons.shopping_cart),
      ),
      (
        label: context.tr('Profile'),
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
      ),
    ];

    if (context.screenSize == ScreenSize.compact) {
      return ScrollNavigationScaffold(
        branchIndex: navigationShell.currentIndex,
        body: navigationShell,
        navigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(context.tr(d.label)),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
