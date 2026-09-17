import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/features/auth/domain/auth_state.dart';
import 'package:yege_wars/features/auth/domain/entities/user_profile.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';

void main() {
  const student = UserProfile(
    id: 'id',
    username: 'pavel',
    role: UserRole.student,
  );
  const admin = UserProfile(id: 'id', username: 'pavel', role: UserRole.admin);

  group('UserRole', () {
    test('разбирает значения из базы данных', () {
      expect(UserRole.fromValue('admin'), UserRole.admin);
      expect(UserRole.fromValue('student'), UserRole.student);
      expect(UserRole.fromValue(null), UserRole.student);
      expect(UserRole.fromValue('root'), UserRole.student);
    });

    test('признак администратора', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.student.isAdmin, isFalse);
    });
  });

  group('UserProfile', () {
    test('равенство по полям', () {
      expect(
        student,
        const UserProfile(id: 'id', username: 'pavel', role: UserRole.student),
      );
      expect(student == admin, isFalse);
      expect(
        student.hashCode,
        const UserProfile(
          id: 'id',
          username: 'pavel',
          role: UserRole.student,
        ).hashCode,
      );
    });

    test('в текстовом виде видны логин и роль', () {
      expect(student.toString(), contains('pavel'));
      expect(admin.toString(), contains('admin'));
    });
  });

  group('AuthState', () {
    test('профиль доступен только в authenticated', () {
      expect(const AuthAuthenticated(student).profileOrNull, student);
      expect(const AuthUnknown().profileOrNull, isNull);
      expect(const AuthUnauthenticated().profileOrNull, isNull);
    });

    test('признаки состояния', () {
      expect(const AuthAuthenticated(student).isAuthenticated, isTrue);
      expect(const AuthAuthenticated(student).isAdmin, isFalse);
      expect(const AuthAuthenticated(admin).isAdmin, isTrue);
      expect(const AuthUnknown().isAuthenticated, isFalse);
      expect(const AuthUnauthenticated().isAdmin, isFalse);
    });

    test('равенство состояний', () {
      expect(const AuthUnknown(), const AuthUnknown());
      expect(const AuthUnauthenticated(), const AuthUnauthenticated());
      expect(
        const AuthUnauthenticated(failure: NetworkFailure()),
        const AuthUnauthenticated(failure: NetworkFailure()),
      );
      expect(
        const AuthUnauthenticated() ==
            const AuthUnauthenticated(
              failure: NetworkFailure(),
            ),
        isFalse,
      );
      expect(
        const AuthAuthenticated(student) == const AuthAuthenticated(admin),
        isFalse,
      );
      expect(
        const AuthAuthenticated(student).hashCode,
        const AuthAuthenticated(student).hashCode,
      );
      expect(const AuthUnknown().hashCode, const AuthUnknown().hashCode);
    });
  });
}
