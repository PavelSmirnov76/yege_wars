import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';

/// Экран профиля пользователя (заглушка этапа 1).
class ProfileScreen extends StatelessWidget {
  /// Создаёт экран профиля.
  const ProfileScreen({super.key});

  /// Размер иконки-заглушки.
  static const double _iconSize = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outlined,
              size: _iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.navProfile, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.comingSoon,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
