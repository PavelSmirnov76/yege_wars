import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';

/// Заголовки статей справочника для внутренних ссылок `[[slug]]`.
///
/// Реализует UC-28.
final class GetArticleTitlesUseCase {
  /// Создаёт use case поверх [ReferenceRepository].
  const GetArticleTitlesUseCase(this._repository);

  final ReferenceRepository _repository;

  /// Загружает словарь «slug — заголовок».
  FutureResult<Map<String, String>> call() => _repository.articleTitles();
}
