import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Экран профиля: логин, роль и выход из аккаунта.
///
/// Прогресс и статистика появятся на этапе 7.
class ProfileScreen extends ConsumerWidget {
  /// Создаёт экран профиля.
  const ProfileScreen({super.key});

  /// Размер иконки-заглушки.
  static const double _iconSize = 64;

  /// Выходит из аккаунта; ошибку показывает всплывающим сообщением.
  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    final failure = result.failureOrNull;
    if (failure == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  /// Русское название роли.
  static String _roleLabel(UserRole role, AppLocalizations l10n) =>
      switch (role) {
        UserRole.student => l10n.profileRoleStudent,
        UserRole.admin => l10n.profileRoleAdmin,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(authControllerProvider).profileOrNull;

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
            Text(
              profile?.username ?? l10n.navProfile,
              style: theme.textTheme.titleLarge,
            ),
            if (profile != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.profileRoleLabel}: ${_roleLabel(profile.role, l10n)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.comingSoon,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => unawaited(_signOut(context, ref)),
              icon: const Icon(Icons.logout),
              label: Text(l10n.profileSignOut),
            ),
          ],
        ),
      ),
    );
  }
}
