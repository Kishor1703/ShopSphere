import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.status == AuthStatus.error) {
      return Scaffold(
        body: SafeArea(
          child: ErrorView(
            title: context.tr('Could not start ShopSphere'),
            message: auth.message ?? 'Please check your connection.',
            onRetry: () => ref.read(authProvider.notifier).restoreSession(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.marine,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                size: 48,
                color: AppColors.onAmber,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ShopSphere',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
