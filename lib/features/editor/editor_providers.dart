import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/features/editor/data/preferences_draft_storage.dart';
import 'package:yege_wars/features/editor/domain/draft_storage.dart';

part 'editor_providers.g.dart';

/// Хранилище черновиков кода.
@Riverpod(keepAlive: true)
DraftStorage draftStorage(Ref ref) => const PreferencesDraftStorage();

/// Черновик кода для задачи.
///
/// Читается один раз при открытии задачи; дальше правки сохраняются
/// редактором с задержкой.
@riverpod
Future<String> taskDraft(Ref ref, String taskSlug) async =>
    await ref.watch(draftStorageProvider).read(taskSlug) ?? '';
