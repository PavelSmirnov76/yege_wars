import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yege_wars/core/network/supabase_client_provider.dart';
import 'package:yege_wars/features/reference/data/datasources/supabase_reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/data/repositories/reference_repository_impl.dart';
import 'package:yege_wars/features/reference/domain/repositories/reference_repository.dart';
import 'package:yege_wars/features/reference/domain/use_cases/get_article_titles_use_case.dart';
import 'package:yege_wars/features/reference/domain/use_cases/get_article_use_case.dart';
import 'package:yege_wars/features/reference/domain/use_cases/list_articles_use_case.dart';

part 'reference_providers.g.dart';

/// Сборка зависимостей справочника.
///
/// В тестах достаточно подменить [referenceRepositoryProvider].
@Riverpod(keepAlive: true)
ReferenceRepository referenceRepository(Ref ref) => ReferenceRepositoryImpl(
  SupabaseReferenceRemoteDataSource(ref.watch(supabaseClientProvider)),
);

/// Use case списка статей.
@Riverpod(keepAlive: true)
ListArticlesUseCase listArticlesUseCase(Ref ref) =>
    ListArticlesUseCase(ref.watch(referenceRepositoryProvider));

/// Use case загрузки статьи.
@Riverpod(keepAlive: true)
GetArticleUseCase getArticleUseCase(Ref ref) =>
    GetArticleUseCase(ref.watch(referenceRepositoryProvider));

/// Use case словаря заголовков для ссылок `[[slug]]`.
@Riverpod(keepAlive: true)
GetArticleTitlesUseCase getArticleTitlesUseCase(Ref ref) =>
    GetArticleTitlesUseCase(ref.watch(referenceRepositoryProvider));
