import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:yege_wars/features/auth/data/dto/profile_dto.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';

void main() {
  group('ProfileDto', () {
    test('разбирает строку профиля и отдаёт сущность', () {
      final profile = ProfileDto.fromJson(const {
        'id': 'user-id',
        'username': 'pavel',
        'role': 'admin',
      }).toDomain();

      expect(profile.id, 'user-id');
      expect(profile.username, 'pavel');
      expect(profile.role, UserRole.admin);
      expect(profile.isAdmin, isTrue);
    });

    test('неизвестная роль трактуется как ученик', () {
      final profile = ProfileDto.fromJson(const {
        'id': 'user-id',
        'username': 'pavel',
        'role': 'superuser',
      }).toDomain();

      expect(profile.role, UserRole.student);
      expect(profile.isAdmin, isFalse);
    });

    test('роль без значения трактуется как ученик', () {
      final profile = ProfileDto.fromJson(const {
        'id': 'user-id',
        'username': 'pavel',
      }).toDomain();

      expect(profile.role, UserRole.student);
    });

    test('бросает FormatException без обязательных полей', () {
      expect(
        () => ProfileDto.fromJson(const {'username': 'pavel'}),
        throwsFormatException,
      );
      expect(
        () => ProfileDto.fromJson(const {'id': 1, 'username': 'pavel'}),
        throwsFormatException,
      );
    });
  });

  group('SupabaseAuthRemoteDataSource.emailFor', () {
    test('логин превращается в техническую почту', () {
      expect(
        SupabaseAuthRemoteDataSource.emailFor('pavel_76'),
        'pavel_76@ege.local',
      );
    });

    test('регистр логина в почте не важен', () {
      expect(
        SupabaseAuthRemoteDataSource.emailFor('Pavel'),
        'pavel@ege.local',
      );
    });
  });
}
