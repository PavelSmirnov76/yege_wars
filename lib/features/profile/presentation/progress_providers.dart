import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/profile/data/progress_repository.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';

part 'progress_providers.g.dart';

/// Зависимости чтения прогресса.
@riverpod
ProgressRepository progressRepository(Ref ref) => ProgressRepositoryImpl(
  ProgressDataSource(ref.watch(supabaseClientProvider)),
);

/// Прогресс отдельного аккаунта. Устаревшие запросы изолированы провайдером.
@riverpod
Future<ProgressSummary> profileProgress(Ref ref, String userId) async {
  final result = await GetProgress(ref.watch(progressRepositoryProvider))(
    userId,
  );
  return result.fold(onOk: (value) => value, onErr: (failure) => throw failure);
}
