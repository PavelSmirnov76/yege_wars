import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Клиент Supabase, инициализированный в `bootstrap`.
///
/// Единственная точка доступа к SDK: остальной код получает клиент
/// только отсюда, поэтому в тестах его легко подменить.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
