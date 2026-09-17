import 'package:yege_wars/core/error/failure.dart';

/// Результат операции: успех [Ok] со значением или ошибка [Err].
///
/// Используется вместо выбрасывания исключений между слоями:
/// data-слой возвращает [Result], presentation-слой разбирает его
/// через [fold] или pattern matching.
sealed class Result<T> {
  const Result();

  /// `true`, если результат успешный.
  bool get isOk => this is Ok<T>;

  /// `true`, если результат содержит ошибку.
  bool get isErr => this is Err<T>;

  /// Значение при успехе, иначе `null`.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// Ошибка при неуспехе, иначе `null`.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Сворачивает результат в одно значение: [onOk] для успеха,
  /// [onErr] для ошибки.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Err<T>(:final failure) => onErr(failure),
  };

  /// Преобразует значение успешного результата через [transform];
  /// ошибка передаётся дальше без изменений.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };
}

/// Успешный результат со значением [value].
final class Ok<T> extends Result<T> {
  /// Создаёт успешный результат.
  const Ok(this.value);

  /// Значение операции.
  final T value;
}

/// Неуспешный результат с ошибкой [failure].
final class Err<T> extends Result<T> {
  /// Создаёт результат с ошибкой.
  const Err(this.failure);

  /// Ошибка операции.
  final Failure failure;
}

/// Асинхронный [Result] — типичный тип возврата репозиториев.
typedef FutureResult<T> = Future<Result<T>>;
