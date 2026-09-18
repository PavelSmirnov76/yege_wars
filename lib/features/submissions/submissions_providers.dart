import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/submissions/data/datasources/supabase_submissions_remote_data_source.dart';
import 'package:yege_wars/features/submissions/data/repositories/submissions_repository_impl.dart';
import 'package:yege_wars/features/submissions/domain/repositories/submissions_repository.dart';
import 'package:yege_wars/features/submissions/domain/use_cases/submit_answer_use_case.dart';

part 'submissions_providers.g.dart';

/// Репозиторий попыток. В тестах подменяется целиком.
@Riverpod(keepAlive: true)
SubmissionsRepository submissionsRepository(Ref ref) =>
    SubmissionsRepositoryImpl(
      SupabaseSubmissionsRemoteDataSource(ref.watch(supabaseClientProvider)),
    );

/// Use case отправки ответа.
@Riverpod(keepAlive: true)
SubmitAnswerUseCase submitAnswerUseCase(Ref ref) =>
    SubmitAnswerUseCase(ref.watch(submissionsRepositoryProvider));
