import 'package:postgres/postgres.dart';
import 'package:seed_tasks/src/exceptions.dart';

/// Разобранная строка подключения к PostgreSQL.
class DatabaseConfig {
  const DatabaseConfig({required this.endpoint, required this.sslMode});

  final Endpoint endpoint;
  final SslMode sslMode;
}

/// Разбирает строку подключения вида `postgres://user:pass@host:port/db`.
///
/// Необязательный query-параметр `sslmode` (disable | require | verify-full)
/// управляет SSL; по умолчанию localhost — без SSL, удалённые хосты
/// (в т.ч. Supabase) — с SSL.
DatabaseConfig parseDatabaseUrl(String url) {
  final Uri uri;
  try {
    uri = Uri.parse(url);
  } on FormatException {
    throw SeedValidationException(
      'SEED_DATABASE_URL: не удалось разобрать URL',
    );
  }
  if (uri.scheme != 'postgres' && uri.scheme != 'postgresql') {
    throw SeedValidationException(
      'SEED_DATABASE_URL: ожидается схема postgres:// или postgresql://',
    );
  }
  if (uri.host.isEmpty) {
    throw SeedValidationException('SEED_DATABASE_URL: не указан хост');
  }
  final database = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  if (database.isEmpty) {
    throw SeedValidationException(
      'SEED_DATABASE_URL: не указано имя базы данных (…/db в конце URL)',
    );
  }
  String? username;
  String? password;
  if (uri.userInfo.isNotEmpty) {
    final parts = uri.userInfo.split(':');
    username = Uri.decodeComponent(parts.first);
    if (parts.length > 1) {
      // Пароль может содержать «:», поэтому склеиваем остаток обратно.
      password = Uri.decodeComponent(parts.sublist(1).join(':'));
    }
  }
  return DatabaseConfig(
    endpoint: Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: database,
      username: username,
      password: password,
    ),
    sslMode: _resolveSslMode(uri),
  );
}

SslMode _resolveSslMode(Uri uri) {
  final raw = uri.queryParameters['sslmode'];
  if (raw == null) {
    const localHosts = {'localhost', '127.0.0.1', '::1'};
    return localHosts.contains(uri.host) ? SslMode.disable : SslMode.require;
  }
  switch (raw) {
    case 'disable':
      return SslMode.disable;
    case 'prefer' || 'require':
      return SslMode.require;
    case 'verify-full':
      return SslMode.verifyFull;
    default:
      throw SeedValidationException(
        'SEED_DATABASE_URL: неизвестный sslmode «$raw» '
        '(допустимо: disable, prefer, require, verify-full)',
      );
  }
}
