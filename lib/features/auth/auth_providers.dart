import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:yege_wars/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:yege_wars/features/auth/domain/repositories/auth_repository.dart';
import 'package:yege_wars/features/auth/domain/use_cases/get_current_profile_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/is_registration_open_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:yege_wars/features/auth/domain/use_cases/watch_auth_user_use_case.dart';

part 'auth_providers.g.dart';

/// Сборка зависимостей фичи авторизации.
///
/// В тестах достаточно подменить [authRepositoryProvider]: use case'ы
/// собираются поверх него и подхватят подмену.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  SupabaseAuthRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Use case входа.
@Riverpod(keepAlive: true)
SignInUseCase signInUseCase(Ref ref) =>
    SignInUseCase(ref.watch(authRepositoryProvider));

/// Use case регистрации.
@Riverpod(keepAlive: true)
SignUpUseCase signUpUseCase(Ref ref) =>
    SignUpUseCase(ref.watch(authRepositoryProvider));

/// Use case выхода.
@Riverpod(keepAlive: true)
SignOutUseCase signOutUseCase(Ref ref) =>
    SignOutUseCase(ref.watch(authRepositoryProvider));

/// Use case загрузки профиля текущего пользователя.
@Riverpod(keepAlive: true)
GetCurrentProfileUseCase getCurrentProfileUseCase(Ref ref) =>
    GetCurrentProfileUseCase(ref.watch(authRepositoryProvider));

/// Use case наблюдения за сессией.
@Riverpod(keepAlive: true)
WatchAuthUserUseCase watchAuthUserUseCase(Ref ref) =>
    WatchAuthUserUseCase(ref.watch(authRepositoryProvider));

/// Use case проверки, открыта ли регистрация.
@Riverpod(keepAlive: true)
IsRegistrationOpenUseCase isRegistrationOpenUseCase(Ref ref) =>
    IsRegistrationOpenUseCase(ref.watch(authRepositoryProvider));

/// Открыта ли регистрация новых пользователей.
///
/// Ошибку отдаёт как `Failure` в `AsyncError`, чтобы экран показал
/// её готовый русский текст.
@riverpod
Future<bool> registrationOpen(Ref ref) async {
  final result = await ref.watch(isRegistrationOpenUseCaseProvider)();
  return result.fold(
    onOk: (isOpen) => isOpen,
    onErr: (failure) => throw failure,
  );
}
