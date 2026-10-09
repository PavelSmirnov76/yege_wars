import 'dart:async';

import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/editor/domain/repositories/draft_repository.dart';

/// Черновики в памяти вместо таблицы `drafts`.
///
/// Правило «пустой код — удаление» здесь не повторяется: его применяет
/// настоящий `SaveDraftUseCase`, а подделка только записывает вызовы.
final class FakeDraftRepository implements DraftRepository {
  /// Черновики по id задачи — как строки в базе.
  final Map<String, String> drafts = {};

  /// Если задан, его вернёт [load] вместо черновика из [drafts].
  Result<String?>? loadResult;

  /// Что вернут [save] и [delete].
  Result<void> writeResult = const Ok<void>(null);

  /// Пока не завершён, [save] и [delete] не отвечают.
  Completer<void>? writeGate;

  /// Пока не завершён, [load] не отвечает: черновик ещё грузится.
  Completer<void>? loadGate;

  /// Сколько раз грузили черновик.
  int loadCalls = 0;

  /// Записи по порядку: код записи или `null` — удаление.
  final List<String?> writes = [];

  @override
  FutureResult<String?> load(String taskId) async {
    loadCalls++;
    await loadGate?.future;
    return loadResult ?? Ok<String?>(drafts[taskId]);
  }

  @override
  FutureResult<void> save(String taskId, String code) async {
    writes.add(code);
    await writeGate?.future;
    if (writeResult.isOk) {
      drafts[taskId] = code;
    }
    return writeResult;
  }

  @override
  FutureResult<void> delete(String taskId) async {
    writes.add(null);
    await writeGate?.future;
    if (writeResult.isOk) {
      drafts.remove(taskId);
    }
    return writeResult;
  }
}
