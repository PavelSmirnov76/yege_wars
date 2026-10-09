import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/editor/data/datasources/supabase_draft_remote_data_source.dart';
import 'package:yege_wars/features/editor/data/repositories/draft_repository_impl.dart';
import 'package:yege_wars/features/editor/domain/repositories/draft_repository.dart';
import 'package:yege_wars/features/editor/domain/use_cases/save_draft_use_case.dart';

part 'editor_providers.g.dart';

/// Черновики кода в базе. В тестах подменяется целиком.
///
/// Живёт всю сессию: в нём очередь записей черновиков.
@Riverpod(keepAlive: true)
DraftRepository draftRepository(Ref ref) => DraftRepositoryImpl(
  SupabaseDraftRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Use case сохранения черновика.
@Riverpod(keepAlive: true)
SaveDraftUseCase saveDraftUseCase(Ref ref) =>
    SaveDraftUseCase(ref.watch(draftRepositoryProvider));
