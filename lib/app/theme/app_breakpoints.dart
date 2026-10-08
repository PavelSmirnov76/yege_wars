/// Брейкпоинты адаптивной вёрстки.
///
/// Границы включающие: ширина, равная [mobileMax], — ещё мобильная,
/// равная [tabletMax] — ещё планшетная.
///
/// Воплощает TOKEN-5.
abstract final class AppBreakpoints {
  /// Максимальная ширина мобильной раскладки.
  static const double mobileMax = 600;

  /// Максимальная ширина планшетной раскладки.
  static const double tabletMax = 1024;

  /// Мобильная раскладка: ширина не больше [mobileMax].
  static bool isMobile(double width) => width <= mobileMax;

  /// Планшетная раскладка: ширина между [mobileMax] и [tabletMax].
  static bool isTablet(double width) => width > mobileMax && width <= tabletMax;

  /// Десктопная раскладка: ширина больше [tabletMax].
  static bool isDesktop(double width) => width > tabletMax;
}
