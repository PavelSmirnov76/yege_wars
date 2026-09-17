import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yege_wars/features/auth/data/datasources/supabase_auth_remote_data_source.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

/// Пользователь Supabase Auth с минимально необходимыми полями.
User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-09-17T12:00:00Z',
);

/// Сессия для [user].
Session _session(User user) =>
    Session(accessToken: 'token', tokenType: 'bearer', user: user);

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late SupabaseAuthRemoteDataSource dataSource;

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    dataSource = SupabaseAuthRemoteDataSource(client);
  });

  test('вход идёт по технической почте', () async {
    when(
      () => auth.signInWithPassword(
        email: 'pavel@ege.local',
        password: 'password1',
      ),
    ).thenAnswer((_) async => AuthResponse(session: _session(_user('uid'))));

    final userId = await dataSource.signIn(
      username: 'pavel',
      password: 'password1',
    );

    expect(userId, 'uid');
  });

  test(
    'регистрация передаёт логин в метаданные без изменения регистра',
    () async {
      when(
        () => auth.signUp(
          email: 'pavel@ege.local',
          password: 'password1',
          data: const {'username': 'Pavel'},
        ),
      ).thenAnswer((_) async => AuthResponse(user: _user('uid')));

      final userId = await dataSource.signUp(
        username: 'Pavel',
        password: 'password1',
      );

      expect(userId, 'uid');
      verify(
        () => auth.signUp(
          email: 'pavel@ege.local',
          password: 'password1',
          data: const {'username': 'Pavel'},
        ),
      ).called(1);
    },
  );

  test('выход делегируется Supabase Auth', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await dataSource.signOut();

    verify(() => auth.signOut()).called(1);
  });

  test('идентификатор текущей сессии', () {
    when(() => auth.currentUser).thenReturn(_user('uid'));
    expect(dataSource.currentUserId, 'uid');

    when(() => auth.currentUser).thenReturn(null);
    expect(dataSource.currentUserId, isNull);
  });

  test('поток сессии отдаёт id и не повторяет одно и то же значение', () {
    final session = _session(_user('uid'));
    when(() => auth.onAuthStateChange).thenAnswer(
      (_) => Stream<AuthState>.fromIterable([
        AuthState(AuthChangeEvent.initialSession, session),
        // Обновление токена не должно приводить к перезагрузке профиля.
        AuthState(AuthChangeEvent.tokenRefreshed, session),
        const AuthState(AuthChangeEvent.signedOut, null),
      ]),
    );

    expect(
      dataSource.watchUserId(),
      emitsInOrder(<Object?>['uid', null, emitsDone]),
    );
  });
}
