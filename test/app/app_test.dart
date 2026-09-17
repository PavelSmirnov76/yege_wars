import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('smoke: приложение стартует на экране входа', (tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository: repository);

    final l10n = AppLocalizationsRu();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(l10n.authLoginTitle), findsOneWidget);
  });
}
