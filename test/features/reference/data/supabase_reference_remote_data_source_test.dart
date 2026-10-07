import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/reference/data/datasources/supabase_reference_remote_data_source.dart';
import 'package:yege_wars/features/reference/domain/entities/article_filter.dart';

import '../../../helpers/recording_supabase_client.dart';

// В postgrest для Dart `order()` по умолчанию сортирует по убыванию,
// поэтому проверяется адрес запроса, который собирает SDK.
void main() {
  late RecordingSupabaseClient supabase;
  late SupabaseReferenceRemoteDataSource dataSource;

  setUp(() {
    supabase = RecordingSupabaseClient();
    dataSource = SupabaseReferenceRemoteDataSource(supabase.client);
  });

  tearDown(() => supabase.dispose());

  test('статьи идут по уровню, затем по названию — по возрастанию', () async {
    await dataSource.fetchArticles(const ArticleFilter());

    expect(supabase.onlyUrl.path, '/rest/v1/reference_articles');
    expect(
      supabase.onlyUrl.queryParameters['order'],
      'level.asc.nullslast,title.asc.nullslast',
    );
  });
}
