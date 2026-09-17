/// Пути и имена маршрутов приложения.
abstract final class AppRoutes {
  /// Путь каталога задач (корень приложения).
  static const String catalog = '/';

  /// Имя маршрута каталога.
  static const String catalogName = 'catalog';

  /// Путь профиля.
  static const String profile = '/profile';

  /// Имя маршрута профиля.
  static const String profileName = 'profile';

  /// Путь админки.
  static const String admin = '/admin';

  /// Имя маршрута админки.
  static const String adminName = 'admin';

  /// Путь экрана входа.
  static const String login = '/login';

  /// Имя маршрута входа.
  static const String loginName = 'login';

  /// Путь экрана регистрации.
  static const String register = '/register';

  /// Имя маршрута регистрации.
  static const String registerName = 'register';

  /// Путь заставки: показывается, пока восстанавливается сессия.
  static const String splash = '/splash';

  /// Имя маршрута заставки.
  static const String splashName = 'splash';

  /// Параметр запроса с адресом, на который пользователь шёл
  /// до показа заставки.
  static const String fromQueryParam = 'from';
}
