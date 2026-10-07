import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Подсказка под полем ответа: в какой форме записать ответ формата
/// [format].
///
/// База сравнивает строгую форму: число вместо текста варианта, запятую
/// без пробела, регистр букв. Поэтому подсказка своя для каждого формата.
String answerFormatHint(AppLocalizations l10n, AnswerFormat format) =>
    switch (format) {
      AnswerFormat.single => l10n.submitHintSingle,
      AnswerFormat.pair => l10n.submitHintPair,
      AnswerFormat.multi => l10n.submitHintMulti,
      AnswerFormat.string => l10n.submitHintString,
    };
