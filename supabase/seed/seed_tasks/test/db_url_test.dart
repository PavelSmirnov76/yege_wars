import 'package:postgres/postgres.dart';
import 'package:seed_tasks/seed_tasks.dart';
import 'package:test/test.dart';

void main() {
  group('parseDatabaseUrl', () {
    test('разбирает полный URL', () {
      final config = parseDatabaseUrl(
        'postgres://seeder:secret@db.example.com:6543/postgres',
      );
      expect(config.endpoint.host, 'db.example.com');
      expect(config.endpoint.port, 6543);
      expect(config.endpoint.database, 'postgres');
      expect(config.endpoint.username, 'seeder');
      expect(config.endpoint.password, 'secret');
    });

    test('порт по умолчанию 5432, схема postgresql:// допустима', () {
      final config = parseDatabaseUrl('postgresql://u:p@host/db');
      expect(config.endpoint.port, 5432);
      expect(config.endpoint.database, 'db');
    });

    test('пароль с percent-кодированием и двоеточием', () {
      final config = parseDatabaseUrl(
        'postgres://u:p%40ss:word@host:5432/db',
      );
      expect(config.endpoint.username, 'u');
      expect(config.endpoint.password, 'p@ss:word');
    });

    test('localhost без sslmode — SSL выключен', () {
      final config = parseDatabaseUrl('postgres://u:p@localhost:5432/db');
      expect(config.sslMode, SslMode.disable);
    });

    test('удалённый хост без sslmode — SSL обязателен', () {
      final config = parseDatabaseUrl(
        'postgres://u:p@db.abc.supabase.co:5432/postgres',
      );
      expect(config.sslMode, SslMode.require);
    });

    test('явный sslmode учитывается', () {
      expect(
        parseDatabaseUrl('postgres://u:p@remote/db?sslmode=disable').sslMode,
        SslMode.disable,
      );
      expect(
        parseDatabaseUrl('postgres://u:p@localhost/db?sslmode=require').sslMode,
        SslMode.require,
      );
      expect(
        parseDatabaseUrl('postgres://u:p@localhost/db?sslmode=prefer').sslMode,
        SslMode.require,
      );
      expect(
        parseDatabaseUrl(
          'postgres://u:p@localhost/db?sslmode=verify-full',
        ).sslMode,
        SslMode.verifyFull,
      );
    });

    test('ошибка: неизвестный sslmode', () {
      expect(
        () => parseDatabaseUrl('postgres://u:p@host/db?sslmode=maybe'),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: не postgres-схема', () {
      expect(
        () => parseDatabaseUrl('mysql://u:p@host/db'),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: нет имени базы данных', () {
      expect(
        () => parseDatabaseUrl('postgres://u:p@host:5432'),
        throwsA(isA<SeedValidationException>()),
      );
    });

    test('ошибка: нет хоста', () {
      expect(
        () => parseDatabaseUrl('postgres:///db'),
        throwsA(isA<SeedValidationException>()),
      );
    });
  });
}
