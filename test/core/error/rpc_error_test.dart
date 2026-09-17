import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/rpc_error.dart';

void main() {
  group('RpcError.tryParse', () {
    test('разбирает формат «[код] Текст»', () {
      final error = RpcError.tryParse(
        '[username_taken] Логин «pavel» уже занят, выберите другой.',
      );

      expect(error?.code, RpcErrorCodes.usernameTaken);
      expect(error?.message, 'Логин «pavel» уже занят, выберите другой.');
    });

    test('игнорирует ведущие пробелы и перенос строки в тексте', () {
      final error = RpcError.tryParse('  [rate_limit] Слишком много\nотправок');

      expect(error?.code, 'rate_limit');
      expect(error?.message, 'Слишком много\nотправок');
    });

    test('возвращает null для сообщения без кода', () {
      expect(RpcError.tryParse('Database error saving new user'), isNull);
      expect(RpcError.tryParse('[invalid_username]'), isNull);
      expect(RpcError.tryParse(null), isNull);
    });
  });
}
