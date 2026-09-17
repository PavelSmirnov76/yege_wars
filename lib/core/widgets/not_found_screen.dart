import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';

/// Экран 404: показывается для несуществующих маршрутов.
class NotFoundScreen extends StatelessWidget {
  /// Создаёт экран 404.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.notFoundTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.notFoundBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go(AppRoutes.catalog),
                child: Text(l10n.notFoundGoHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
