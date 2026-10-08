import 'package:shared_preferences/shared_preferences.dart';
import 'package:yege_wars/features/editor/domain/draft_storage.dart';

/// Черновики в локальном хранилище браузера.
///
/// Реализует UC-16.
final class PreferencesDraftStorage implements DraftStorage {
  /// Создаёт хранилище.
  const PreferencesDraftStorage();

  /// Префикс ключа, чтобы не пересечься с чужими настройками.
  static const String keyPrefix = 'draft.';

  /// Ключ черновика задачи.
  static String keyOf(String taskSlug) => '$keyPrefix$taskSlug';

  @override
  Future<String?> read(String taskSlug) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(keyOf(taskSlug));
  }

  @override
  Future<void> write(String taskSlug, String code) async {
    final preferences = await SharedPreferences.getInstance();
    if (code.trim().isEmpty) {
      await preferences.remove(keyOf(taskSlug));
      return;
    }
    await preferences.setString(keyOf(taskSlug), code);
  }
}
