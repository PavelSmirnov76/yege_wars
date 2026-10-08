/// Пути и имена маршрутов приложения.
abstract final class AppRoutes {
  /// Путь каталога задач (корень приложения).
  static const String catalog = '/';

  /// Имя маршрута каталога.
  static const String catalogName = 'catalog';

  /// Имя маршрута страницы задачи.
  static const String taskName = 'task';

  /// Путь справочника.
  static const String reference = '/reference';

  /// Имя маршрута справочника.
  static const String referenceName = 'reference';

  /// Имя маршрута статьи справочника.
  static const String referenceArticleName = 'referenceArticle';

  /// Имя параметра пути с идентификатором статьи или задачи.
  static const String slugParam = 'slug';

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

  /// Параметр запроса с адресом, на который шёл пользователь: его хранят
  /// заставка, экраны входа и регистрации, а открывают после проверки
  /// сессии, входа (UC-10) или регистрации (UC-1).
  static const String fromQueryParam = 'from';
}
