import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/tasks/data/dto/task_dto.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_difficulty.dart';

void main() {
  Map<String, dynamic> row({Object? egeNumber = 24}) => {
    'id': 'task-1',
    'slug': 'fipi-48f84f',
    'title': 'Задание банка',
    'ege_number': egeNumber,
    'difficulty': 3,
    'tags': ['3.13'],
  };

  group('TaskDto.toBrief', () {
    test('читает номер задания', () {
      final brief = TaskDto.toBrief(row());

      expect(brief.egeNumber, 24);
      expect(brief.difficulty, TaskDifficulty.hard);
      expect(brief.tags, ['3.13']);
    });

    test('задание без номера КИМ получает null, а не ноль', () {
      final brief = TaskDto.toBrief(row(egeNumber: null));

      expect(brief.egeNumber, isNull);
    });

    test('строка без обязательных полей — ошибка формата', () {
      expect(
        () => TaskDto.toBrief({'id': 'task-1'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
