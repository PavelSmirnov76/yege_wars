import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/core/network/supabase_schema.dart';
import 'package:yege_wars/features/auth/data/datasources/auth_remote_data_source.dart';

/// Реализация [AuthRemoteDataSource] поверх [SupabaseClient].
final class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  /// Создаёт datasource поверх клиента [SupabaseClient].
  const SupabaseAuthRemoteDataSource(this._client);

  /// Домен технической почты: почту не отправляем, она нужна только
  /// Supabase Auth, который умеет работать лишь с email или телефоном.
  static const String emailDomain = 'ege.local';

  /// Техническая почта для логина [username].
  ///
  /// Регистр приводится к нижнему: Supabase Auth всё равно нормализует
  /// email, а логин в `profiles` сохраняется в исходном виде.
  static String emailFor(String username) =>
      '${username.toLowerCase()}@$emailDomain';

  final SupabaseClient _client;

  @override
  Stream<String?> watchUserId() => _client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct();

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) => _client
      .from(SupabaseTables.profiles)
      .select()
      .eq(ProfileColumns.id, userId)
      .maybeSingle();

  @override
  Future<String?> signIn({
    required String username,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: emailFor(username),
      password: password,
    );
    return response.user?.id;
  }

  @override
  Future<String?> signUp({
    required String username,
    required String password,
  }) async {
    // Профиль создаёт триггер handle_new_user, логин он берёт отсюда.
    final response = await _client.auth.signUp(
      email: emailFor(username),
      password: password,
      data: {ProfileColumns.username: username},
    );
    return response.user?.id;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> isRegistrationOpen() =>
      _client.rpc<bool>(SupabaseRpc.isRegistrationOpen);
}
