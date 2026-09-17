import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yege_wars/app/app.dart';

/// Точка входа приложения.
void main() => runApp(const ProviderScope(child: YegeWarsApp()));
