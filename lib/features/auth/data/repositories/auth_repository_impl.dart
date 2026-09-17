import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';
import 'package:yege_wars/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:yege_wars/features/auth/data/dto/profile_dto.dart';
import 'package:yege_wars/features/auth/data/mappers/auth_error_mapper.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';

/// Реализация [AuthRepository] поверх [AuthRemoteDataSource].
///
/// Единственное место, где исключения SDK превращаются в [Failure]:
/// наружу уходит только [Result].
final class AuthRepositoryImpl implements AuthRepository {
  /// Создаёт репозиторий поверх [AuthRemoteDataSource].
  const AuthRepositoryImpl(this._dataSource);

  static const String _sessionMissing = 'Сессия не найдена. Войдите заново.';

  static const String _profileMissing =
      'Профиль пользователя не найден. Обратитесь к преподавателю.';

  static const String _signInFailed = 'Не удалось войти. Попробуйте ещё раз.';

  static const String _signUpFailed =
      'Не удалось зарегистрироваться. Попробуйте ещё раз.';

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<String?> watchUserId() => _dataSource.watchUserId();

  @override
  FutureResult<UserProfile> currentProfile() async {
    try {
      final userId = _dataSource.currentUserId;
      if (userId == null) {
        return const Err<UserProfile>(AuthFailure(message: _sessionMissing));
      }
      return await _profileOf(userId);
    } on Object catch (error) {
      return Err<UserProfile>(AuthErrorMapper.map(error));
    }
  }

  @override
  FutureResult<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final userId = await _dataSource.signIn(
        username: username,
        password: password,
      );
      if (userId == null) {
        return const Err<UserProfile>(AuthFailure(message: _signInFailed));
      }
      return await _profileOf(userId);
    } on Object catch (error) {
      return Err<UserProfile>(
        AuthErrorMapper.map(error, operation: AuthOperation.signIn),
      );
    }
  }

  @override
  FutureResult<UserProfile> signUp({
    required String username,
    required String password,
  }) async {
    try {
      final userId = await _dataSource.signUp(
        username: username,
        password: password,
      );
      if (userId == null) {
        return const Err<UserProfile>(AuthFailure(message: _signUpFailed));
      }
      return await _profileOf(userId);
    } on Object catch (error) {
      return Err<UserProfile>(
        AuthErrorMapper.map(error, operation: AuthOperation.signUp),
      );
    }
  }

  @override
  FutureResult<void> signOut() async {
    try {
      await _dataSource.signOut();
      return const Ok<void>(null);
    } on Object catch (error) {
      return Err<void>(AuthErrorMapper.map(error));
    }
  }

  @override
  FutureResult<bool> isRegistrationOpen() async {
    try {
      return Ok<bool>(await _dataSource.isRegistrationOpen());
    } on Object catch (error) {
      return Err<bool>(AuthErrorMapper.map(error));
    }
  }

  /// Читает профиль по [userId] и превращает его в сущность domain-слоя.
  Future<Result<UserProfile>> _profileOf(String userId) async {
    final json = await _dataSource.fetchProfile(userId);
    if (json == null) {
      return const Err<UserProfile>(DatabaseFailure(message: _profileMissing));
    }
    return Ok<UserProfile>(ProfileDto.fromJson(json).toDomain());
  }
}
