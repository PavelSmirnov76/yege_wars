import 'package:flutter_test/flutter_test.dart';
import 'package:yege_wars/features/tasks/data/dto/task_dto.dart';
import 'package:yege_wars/features/tasks/domain/entities/answer_format.dart';
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

  group('TaskDto.toDetail', () {
    test('формат ответа разбирается в перечисление', () {
      final detail = TaskDto.toDetail(
        {...row(), 'answer_format': 'multi'},
        files: const [],
        articles: const [],
      );

      expect(detail.answerFormat, AnswerFormat.multi);
    });

    test('неизвестный формат ответа не роняет разбор', () {
      final detail = TaskDto.toDetail(
        {...row(), 'answer_format': 'matrix'},
        files: const [],
        articles: const [],
      );

      expect(detail.answerFormat, AnswerFormat.string);
    });
  });

  group('TaskDto.toThemeArticles', () {
    test('прикладывает карточку статьи к строке темы по id', () {
      final articles = TaskDto.toThemeArticles(
        [
          {'article_id': 'a-2', 'sort_order': 1},
          {'article_id': 'a-1', 'sort_order': 0},
        ],
        [
          {
            'id': 'a-1',
            'slug': 'kes-3-2',
            'title': 'Тема 3.2',
            'summary': 'Кратко.',
            'level': 2,
            'reading_minutes': 9,
            'ege_numbers': [25],
            'tags': ['3.2'],
          },
          {'id': 'a-2', 'slug': 'kes-3-3', 'title': 'Тема 3.3'},
        ],
      );

      expect(articles.map((item) => item.article.slug), [
        'kes-3-3',
        'kes-3-2',
      ]);
      expect(articles.map((item) => item.themeOrder), [1, 0]);
      expect(articles.last.article.egeNumbers, [25]);
      expect(articles.last.article.readingMinutes, 9);
    });

    test('строка темы без видимой статьи пропускается', () {
      final articles = TaskDto.toThemeArticles(
        [
          {'article_id': 'hidden', 'sort_order': 0},
          {'article_id': 'a-1', 'sort_order': null},
          {'article_id': 'a-1', 'sort_order': 1},
        ],
        [
          {'id': 'a-1', 'slug': 'kes-3-3', 'title': 'Тема 3.3'},
        ],
      );

      expect(articles.single.article.slug, 'kes-3-3');
      expect(articles.single.themeOrder, 1);
    });
  });
}
