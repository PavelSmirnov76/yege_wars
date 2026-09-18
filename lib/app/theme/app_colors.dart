import 'package:flutter/material.dart';

/// Цветовые токены приложения (тёмная тема).
///
/// Единственный источник цветов: вне этого класса цвета не хардкодятся.
/// Палитра — тёмный графит с одним красно-оранжевым акцентом; текстовые
/// цвета подобраны с контрастом не ниже WCAG AA относительно [background].
abstract final class AppColors {
  /// Основной фон приложения — графитовый.
  static const Color background = Color(0xFF0F1115);

  /// Фон карточек и панелей, чуть светлее [background].
  static const Color surface = Color(0xFF161A21);

  /// Фон приподнятых элементов (меню, диалоги, снэкбары).
  static const Color surfaceElevated = Color(0xFF1D232E);

  /// Цвет границ и разделителей.
  static const Color border = Color(0xFF2A3039);

  /// Основной текст (контраст ~15:1 на [background]).
  static const Color textPrimary = Color(0xFFE8EAEE);

  /// Второстепенный текст (контраст ~7:1 на [background]).
  static const Color textSecondary = Color(0xFF9AA3B2);

  /// Неактивный текст и подписи disabled-элементов.
  static const Color textDisabled = Color(0xFF5D6572);

  /// Акцент — насыщенный красно-оранжевый.
  static const Color accent = Color(0xFFFF4E2A);

  /// Акцент при наведении/нажатии — светлее основного.
  static const Color accentHover = Color(0xFFFF6A47);

  /// Текст и иконки поверх акцентного цвета (контраст ~5.7:1).
  static const Color onAccent = Color(0xFF140A06);

  /// Успех: верное решение, пройденные тесты.
  static const Color success = Color(0xFF3ECF8E);

  /// Предупреждение: частичное решение, важные подсказки.
  static const Color warning = Color(0xFFFFB454);

  /// Ошибка: неверный ответ, упавшие тесты, деструктивные действия.
  static const Color danger = Color(0xFFFF5566);

  /// Метка лёгкой задачи.
  static const Color difficultyEasy = Color(0xFF4ADE80);

  /// Метка задачи средней сложности.
  static const Color difficultyMedium = Color(0xFFF2A33C);

  /// Метка сложной задачи.
  static const Color difficultyHard = Color(0xFFFF4D6D);

  /// Фон блоков кода и редактора — темнее [background].
  static const Color codeBackground = Color(0xFF0B0D11);

  /// Ключевое слово в подсвеченном коде.
  static const Color codeKeyword = Color(0xFFFF7A59);

  /// Встроенная функция или тип в подсвеченном коде.
  static const Color codeBuiltin = Color(0xFF7FB2FF);

  /// Строковый литерал в подсвеченном коде.
  static const Color codeString = Color(0xFF6FD08C);

  /// Числовой литерал в подсвеченном коде.
  static const Color codeNumber = Color(0xFFE2B86B);

  /// Комментарий в подсвеченном коде.
  static const Color codeComment = Color(0xFF6B7484);
}
