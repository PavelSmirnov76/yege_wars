import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/features/auth/presentation/screens/login_screen.dart';
import 'package:yege_wars/l10n/gen/app_localizations_ru.dart';

void main() {
  testWidgets('smoke: приложение стартует на экране входа', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YegeWarsApp()));
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsRu();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(l10n.authLoginTitle), findsOneWidget);
  });
}
