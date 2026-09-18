import 'package:flutter/material.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';

/// Сообщение об ошибке с кнопкой повтора.
class ReferenceErrorView extends StatelessWidget {
  /// Создаёт сообщение по ошибке [error].
  const ReferenceErrorView({
    required this.error,
    required this.onRetry,
    super.key,
  });

  /// Ошибка: `Failure` показывается своим текстом, прочее — общим.
  final Object error;

  /// Повторная попытка загрузки.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is Failure
                  ? (error as Failure).message
                  : l10n.errorUnexpected,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
