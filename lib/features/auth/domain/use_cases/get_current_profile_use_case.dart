import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Профиль текущего пользователя.
final class GetCurrentProfileUseCase {
  /// Создаёт use case поверх [AuthRepository].
  const GetCurrentProfileUseCase(this._repository);

  final AuthRepository _repository;

  /// Загружает профиль вошедшего пользователя.
  FutureResult<UserProfile> call() => _repository.currentProfile();
}
