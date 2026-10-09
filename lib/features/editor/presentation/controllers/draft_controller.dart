import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/features/editor/domain/use_cases/save_draft_use_case.dart';
import 'package:yege_wars/features/editor/editor_providers.dart';

part 'draft_controller.g.dart';

/// Пауза после последней правки, через которую черновик записывается.
const Duration draftSaveDelay = Duration(seconds: 1);

/// Черновик кода на странице задачи.
///
/// Грузится вместе с задачей: пока черновик не пришёл, страница не открыта,
/// а сбой его загрузки — сбой страницы. Пока страница открыта, держит
/// текущий код в памяти — не в хранилище браузера, — поэтому смена вкладки
/// или раскладки код не теряет. Записывает его через [draftSaveDelay] после
/// последней правки, а [flush] — сразу; страница снята — тоже сразу.
///
/// Пишется только код, который отличается от последнего записанного или
/// загруженного: брошенная открытой страница не затрёт черновик, сохранённый
/// на другом устройстве. Сбой записи экран не показывает: код остаётся
/// незаписанным, и его запишет следующая запись.
///
/// Реализует UC-31.
@riverpod
class DraftController extends _$DraftController {
  late String _taskId;
  late SaveDraftUseCase _save;
  Timer? _timer;

  /// Код в поле.
  String _code = '';

  /// Код, который, насколько известно, лежит в базе.
  String _stored = '';

  @override
  Future<String> build(String taskId) async {
    _taskId = taskId;
    _save = ref.watch(saveDraftUseCaseProvider);
    final repository = ref.watch(draftRepositoryProvider);
    // Страница снята — незаписанное уходит сразу; ref здесь уже не нужен.
    ref.onDispose(() {
      _timer?.cancel();
      if (_code != _stored) {
        unawaited(_save(taskId: _taskId, code: _code));
      }
    });

    final result = await repository.load(taskId);
    final code = result.fold(
      onOk: (code) => code ?? '',
      onErr: (failure) => throw failure,
    );
    _code = code;
    _stored = code;
    return code;
  }

  /// Текущий код поля.
  String currentCode() => _code;

  /// Код в поле изменился: запись — через [draftSaveDelay] после последней
  /// правки.
  void edit(String code) {
    if (code == _code) {
      return;
    }
    _code = code;
    _timer?.cancel();
    _timer = Timer(draftSaveDelay, flush);
  }

  /// Записывает код сразу; ответа записи не ждёт.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_code != _stored) {
      unawaited(_write(_code));
    }
  }

  /// Записывает [code] и, если вышло, запоминает его записанным.
  Future<void> _write(String code) async {
    final result = await _save(taskId: _taskId, code: code);
    if (result.isOk) {
      _stored = code;
    }
  }
}
