import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Настоящий [SupabaseClient], который не ходит в сеть.
///
/// Каждый HTTP-запрос запоминается в [requests], ответ на него — пустой
/// список. Нужен, чтобы проверять адрес запроса, который на самом деле
/// собирает SDK, а не заглушку построителя запросов.
final class RecordingSupabaseClient {
  /// Создаёт клиент с пустым журналом запросов.
  RecordingSupabaseClient() {
    client = SupabaseClient(
      'http://localhost',
      'test-anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        // postgrest читает метод из request ответа: без него падает.
        return http.Response(
          '[]',
          200,
          headers: const {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  }

  /// Запросы в порядке отправки.
  final List<http.Request> requests = [];

  /// Клиент для datasource под тестом.
  late final SupabaseClient client;

  /// Единственный отправленный запрос.
  Uri get onlyUrl => requests.single.url;

  /// Освобождает ресурсы клиента.
  Future<void> dispose() => client.dispose();
}
