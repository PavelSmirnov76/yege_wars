import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/tasks/data/datasources/supabase_tasks_remote_data_source.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_filter.dart';

import '../../../helpers/recording_supabase_client.dart';

// В postgrest для Dart `order()` по умолчанию сортирует по убыванию,
// поэтому проверяется адрес запроса, который собирает SDK.
void main() {
  late RecordingSupabaseClient supabase;
  late SupabaseTasksRemoteDataSource dataSource;

  setUp(() {
    supabase = RecordingSupabaseClient();
    dataSource = SupabaseTasksRemoteDataSource(supabase.client);
  });

  tearDown(() => supabase.dispose());

  test('каталог идёт по номеру, затем по названию — по возрастанию', () async {
    await dataSource.fetchTasks(const TaskFilter());

    expect(supabase.onlyUrl.path, '/rest/v1/tasks_public');
    expect(
      supabase.onlyUrl.queryParameters['order'],
      'ege_number.asc.nullslast,title.asc.nullslast',
    );
  });

  test('файлы задачи идут по sort_order по возрастанию', () async {
    await dataSource.fetchFiles('task-id');

    expect(supabase.onlyUrl.path, '/rest/v1/task_files');
    expect(
      supabase.onlyUrl.queryParameters['order'],
      'sort_order.asc.nullslast',
    );
  });

  test('номера для фильтра идут по возрастанию', () async {
    await dataSource.fetchEgeNumbers();

    expect(supabase.onlyUrl.path, '/rest/v1/tasks_public');
    expect(
      supabase.onlyUrl.queryParameters['order'],
      'ege_number.asc.nullslast',
    );
  });
}
