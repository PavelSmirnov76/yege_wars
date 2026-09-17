import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:seed_tasks/src/models.dart';

/// Итог загрузки банка: какие slug вставлены, какие обновлены.
class SeedResult {
  const SeedResult({required this.inserted, required this.updated});

  final List<String> inserted;
  final List<String> updated;
}

/// Идемпотентный upsert задачи по slug: вставка или обновление всех полей.
/// files и tags передаются как JSON-текст и разворачиваются в SQL,
/// «xmax = 0» отличает вставку от обновления существующей строки.
const String _upsertTaskSql = '''
insert into public.tasks (
  slug, ege_number, title, statement_md, difficulty, answer_format,
  files, tags, is_published, source
)
values (
  @slug,
  @egeNumber,
  @title,
  @statementMd,
  @difficulty,
  @answerFormat,
  cast(@files as jsonb),
  (
    -- text[] из JSON-массива тегов, порядок элементов сохраняется
    select coalesce(array_agg(t.value order by t.ord), array[]::text[])
    from jsonb_array_elements_text(cast(@tags as jsonb))
      with ordinality as t(value, ord)
  ),
  @isPublished,
  @source
)
on conflict (slug) do update set
  ege_number    = excluded.ege_number,
  title         = excluded.title,
  statement_md  = excluded.statement_md,
  difficulty    = excluded.difficulty,
  answer_format = excluded.answer_format,
  files         = excluded.files,
  tags          = excluded.tags,
  is_published  = excluded.is_published,
  source        = excluded.source
returning id, (xmax = 0) as inserted
''';

/// Идемпотентный upsert ответа по task_id.
const String _upsertAnswerSql = '''
insert into public.task_answers (task_id, answer)
values (cast(@taskId as uuid), @answer)
on conflict (task_id) do update set answer = excluded.answer
''';

/// Загружает банк задач в одной транзакции: upsert tasks по slug и
/// upsert task_answers по task_id. Ничего не удаляет, повторный запуск
/// не меняет число строк.
Future<SeedResult> seedBank({
  required Connection connection,
  required List<TaskSeed> tasks,
  required Map<String, String> answers,
  required bool publish,
}) {
  return connection.runTx((session) async {
    final inserted = <String>[];
    final updated = <String>[];
    for (final task in tasks) {
      final result = await session.execute(
        Sql.named(_upsertTaskSql),
        parameters: {
          'slug': task.slug,
          'egeNumber': task.egeNumber,
          'title': task.title,
          'statementMd': task.statementMd,
          'difficulty': task.difficulty,
          'answerFormat': task.answerFormat,
          'files': jsonEncode(task.files),
          'tags': jsonEncode(task.tags),
          'isPublished': publish,
          'source': task.source,
        },
      );
      final row = result.first;
      final taskId = row[0]! as String;
      final wasInserted = row[1]! as bool;
      (wasInserted ? inserted : updated).add(task.slug);
      await session.execute(
        Sql.named(_upsertAnswerSql),
        parameters: {'taskId': taskId, 'answer': answers[task.slug]},
      );
    }
    return SeedResult(inserted: inserted, updated: updated);
  });
}
