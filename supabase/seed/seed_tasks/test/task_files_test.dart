import 'package:seed_tasks/seed_tasks.dart';
import 'package:test/test.dart';

void main() {
  group('buildTaskFiles', () {
    test('исключает task.yaml и statement.md, сортирует и строит пути', () {
      final files = buildTaskFiles(
        egeNumber: 17,
        slug: 'e17-pairs-file',
        fileNames: ['task.yaml', '17.txt', 'statement.md', 'data.csv'],
      );
      expect(files, [
        'task_files/17/e17-pairs-file/17.txt',
        'task_files/17/e17-pairs-file/data.csv',
      ]);
    });

    test('пропускает скрытые файлы (например .DS_Store)', () {
      final files = buildTaskFiles(
        egeNumber: 5,
        slug: 'e5-x',
        fileNames: ['.DS_Store', 'task.yaml', 'statement.md', 'input.txt'],
      );
      expect(files, ['task_files/5/e5-x/input.txt']);
    });

    test('без файлов данных возвращает пустой список', () {
      final files = buildTaskFiles(
        egeNumber: 5,
        slug: 'e5-x',
        fileNames: ['task.yaml', 'statement.md'],
      );
      expect(files, isEmpty);
    });

    test('сортировка детерминирована', () {
      final files = buildTaskFiles(
        egeNumber: 24,
        slug: 'e24-run',
        fileNames: ['b.txt', 'a.txt', 'c.txt'],
      );
      expect(files, [
        'task_files/24/e24-run/a.txt',
        'task_files/24/e24-run/b.txt',
        'task_files/24/e24-run/c.txt',
      ]);
    });
  });
}
