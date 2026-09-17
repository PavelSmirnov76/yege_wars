import 'package:yege_wars/features/auth/domain/auth_rules.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Валидаторы полей форм авторизации.
///
/// Правила берутся из [AuthRules] (общие с domain-слоем и БД),
/// тексты — из l10n.
abstract final class AuthFieldValidators {
  /// Проверяет логин; возвращает текст ошибки или `null`.
  static String? username(String? value, AppLocalizations l10n) =>
      AuthRules.isValidUsername(value?.trim() ?? '')
      ? null
      : l10n.authUsernameInvalid;

  /// Проверяет пароль; возвращает текст ошибки или `null`.
  static String? password(String? value, AppLocalizations l10n) =>
      AuthRules.isValidPassword(value ?? '') ? null : l10n.authPasswordInvalid;
}
