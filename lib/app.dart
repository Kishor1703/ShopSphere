import 'package:flutter/material.dart';
import 'core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class ShopSphereApp extends ConsumerWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ShopSphere',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      locale: ref.watch(localeProvider),
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppMaterialDelegate(),
        AppWidgetsDelegate()
      ],
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
