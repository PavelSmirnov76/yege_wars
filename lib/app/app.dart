import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/router/app_router.dart';
import 'package:yege_wars/app/theme/app_theme.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Корневой виджет приложения.
class YegeWarsApp extends ConsumerWidget {
  /// Создаёт корневой виджет.
  const YegeWarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.dark(),
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
