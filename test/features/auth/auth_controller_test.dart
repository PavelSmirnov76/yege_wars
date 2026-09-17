import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/auth/domain/auth_status.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('AuthController', () {
    late ProviderContainer container;

    setUp(() {
      // Подписка удерживает autoDispose-провайдер живым на время теста.
      container = ProviderContainer()
        ..listen(authControllerProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('начальное состояние — unauthenticated', () {
      expect(
        container.read(authControllerProvider),
        AuthStatus.unauthenticated,
      );
    });

    test('signIn переводит в authenticated', () {
      container.read(authControllerProvider.notifier).signIn();

      expect(
        container.read(authControllerProvider),
        AuthStatus.authenticated,
      );
    });

    test('signOut возвращает в unauthenticated', () {
      container.read(authControllerProvider.notifier)
        ..signIn()
        ..signOut();

      expect(
        container.read(authControllerProvider),
        AuthStatus.unauthenticated,
      );
    });
  });
}
