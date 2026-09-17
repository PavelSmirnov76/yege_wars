import 'package:flutter/widgets.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Короткий доступ к локализованным строкам через [BuildContext].
extension L10nX on BuildContext {
  /// Локализованные строки приложения.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
