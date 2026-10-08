import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Открыта ли регистрация новых пользователей.
///
/// Реализует UC-1.
final class IsRegistrationOpenUseCase {
  /// Создаёт use case поверх [AuthRepository].
  const IsRegistrationOpenUseCase(this._repository);

  final AuthRepository _repository;

  /// Запрашивает состояние регистрации.
  FutureResult<bool> call() => _repository.isRegistrationOpen();
}
