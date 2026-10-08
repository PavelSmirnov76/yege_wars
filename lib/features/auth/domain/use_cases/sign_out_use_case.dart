import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Выход из аккаунта.
///
/// Реализует UC-13.
final class SignOutUseCase {
  /// Создаёт use case поверх [AuthRepository].
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  /// Выполняет выход.
  FutureResult<void> call() => _repository.signOut();
}
