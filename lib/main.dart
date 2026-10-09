import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/app.dart';
import 'package:yege_wars/app/bootstrap.dart';
import 'package:yege_wars/app/not_configured_app.dart';
import 'package:yege_wars/app/provider_retry.dart';

/// Точка входа приложения.
Future<void> main() async {
  final result = await bootstrap();
  runApp(
    result.fold(
      onOk: (_) => const ProviderScope(
        retry: noProviderRetry,
        child: YegeWarsApp(),
      ),
      onErr: (failure) => NotConfiguredApp(details: failure.message),
    ),
  );
}
