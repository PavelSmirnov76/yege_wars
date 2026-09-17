import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_theme.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Приложение-заглушка: окружение не настроено или Supabase недоступен.
///
/// Показывается вместо основного приложения, чтобы вместо белого экрана
/// или падения пользователь видел понятное объяснение.
class NotConfiguredApp extends StatelessWidget {
  /// Создаёт заглушку с техническими подробностями [details].
  const NotConfiguredApp({this.details, super.key});

  /// Максимальная ширина текстового блока.
  static const double _maxWidth = 480;

  /// Размер иконки.
  static const double _iconSize = 56;

  /// Подробности ошибки: готовый русский текст.
  final String? details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: _iconSize,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.configMissingTitle,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        details ?? l10n.configMissingBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
