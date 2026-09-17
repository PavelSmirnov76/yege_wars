import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Наблюдение за идентификатором вошедшего пользователя.
final class WatchAuthUserUseCase {
  /// Создаёт use case поверх [AuthRepository].
  const WatchAuthUserUseCase(this._repository);

  final AuthRepository _repository;

  /// Поток `id` пользователя (`null` — пользователь вышел).
  Stream<String?> call() => _repository.watchUserId();
}
