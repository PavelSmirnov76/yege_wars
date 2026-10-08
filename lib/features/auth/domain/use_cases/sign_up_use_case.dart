import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/credentials_validation.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Регистрация по логину и паролю с предварительной проверкой ввода.
///
/// Реализует UC-1.
final class SignUpUseCase {
  /// Создаёт use case поверх [AuthRepository].
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  /// Выполняет регистрацию.
  FutureResult<UserProfile> call({
    required String username,
    required String password,
  }) async {
    final failure = CredentialsValidation.validate(
      username: username,
      password: password,
    );
    if (failure != null) {
      return Err(failure);
    }
    return _repository.signUp(username: username, password: password);
  }
}
