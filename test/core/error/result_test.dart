import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/error/result.dart';

void main() {
  const testFailure = UnexpectedFailure();

  group('Result.fold', () {
    test('для Ok вызывает onOk со значением', () {
      const result = Ok<int>(42);

      final folded = result.fold(
        onOk: (value) => 'ok:$value',
        onErr: (failure) => 'err',
      );

      expect(folded, 'ok:42');
    });

    test('для Err вызывает onErr с ошибкой', () {
      const result = Err<int>(testFailure);

      final folded = result.fold(
        onOk: (value) => 'ok',
        onErr: (failure) => 'err:${failure.message}',
      );

      expect(folded, 'err:${testFailure.message}');
    });
  });

  group('Result.map', () {
    test('для Ok преобразует значение', () {
      const result = Ok<int>(2);

      final mapped = result.map((value) => value * 10);

      expect(mapped, isA<Ok<int>>());
      expect(mapped.valueOrNull, 20);
    });

    test('для Ok меняет тип значения', () {
      const result = Ok<int>(7);

      final mapped = result.map((value) => 'v$value');

      expect(mapped, isA<Ok<String>>());
      expect(mapped.valueOrNull, 'v7');
    });

    test('для Err сохраняет исходную ошибку', () {
      const result = Err<int>(testFailure);

      final mapped = result.map((value) => value.toString());

      expect(mapped, isA<Err<String>>());
      expect(mapped.failureOrNull, same(testFailure));
    });
  });

  group('Result.valueOrNull / failureOrNull', () {
    test('Ok возвращает значение и null вместо ошибки', () {
      const result = Ok<int>(7);

      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
    });

    test('Err возвращает ошибку и null вместо значения', () {
      const result = Err<int>(testFailure);

      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(testFailure));
    });
  });

  group('Result.isOk / isErr', () {
    test('Ok: isOk true, isErr false', () {
      const result = Ok<int>(1);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
    });

    test('Err: isOk false, isErr true', () {
      const result = Err<int>(testFailure);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
    });
  });
}
