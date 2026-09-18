import 'package:yege_wars/features/reference/domain/entities/article_level.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Русское название уровня статьи.
String articleLevelLabel(ArticleLevel level, AppLocalizations l10n) =>
    switch (level) {
      ArticleLevel.basic => l10n.referenceLevelBasic,
      ArticleLevel.medium => l10n.referenceLevelMedium,
      ArticleLevel.advanced => l10n.referenceLevelAdvanced,
    };
