import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Workflow выкладки; путь от корня проекта — `flutter test` идёт из него.
const String _workflowPath = '.github/workflows/deploy.yml';

/// Поддельные значения секретов: тест следит, чтобы их не было в логе.
const String _fakeUrl = 'https://fake-project.invalid';
const String _fakeKey = 'fake-publishable-key';
const String _fakeTestUsername = 'fake-test-user';
const String _fakeTestPassword = 'fake-test-password';

/// Имена обязательных секретов сборки (ENT-5).
const List<String> _secretNames = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

/// Имена необязательных секретов тестового входа (ENT-17).
const List<String> _testLoginSecretNames = [
  'TEST_LOGIN_USERNAME',
  'TEST_LOGIN_PASSWORD',
];

/// Команда сборки — по ней ищется шаг сборки.
const String _buildCommand = 'flutter build web';

/// Проверки перед сборкой, как в задаче build из ci.yml: часть команды, по
/// которой ищется шаг, и вызов, который шаг делает.
const List<(String, List<String>)> _checks = [
  ('flutter pub get', ['flutter', 'pub', 'get']),
  (
    _formatCommand,
    ['dart', 'format', '--output=none', '--set-exit-if-changed'],
  ),
  ('flutter gen-l10n', ['flutter', 'gen-l10n']),
  ('dart run build_runner', ['dart', 'run', 'build_runner', 'build']),
  (
    'flutter analyze',
    ['flutter', 'analyze', '--fatal-infos', '--fatal-warnings'],
  ),
  ('dart run custom_lint', ['dart', 'run', 'custom_lint']),
  ('flutter test', ['flutter', 'test']),
];

/// Форматирование дописывает к вызову список файлов от `find` — его тест не
/// сверяет.
const String _formatCommand = 'dart format';

void main() {
  late YamlMap workflow;
  late YamlMap build;
  late YamlMap deploy;
  late List<YamlMap> buildSteps;

  setUpAll(() {
    workflow = loadYaml(File(_workflowPath).readAsStringSync()) as YamlMap;
    final jobs = workflow['jobs'] as YamlMap;
    build = jobs['build'] as YamlMap;
    deploy = jobs['deploy'] as YamlMap;
    buildSteps = (build['steps'] as YamlList).cast<YamlMap>().toList();
  });

  test(
    'UC-29-P-01: выкладка запускается только вручную — workflow_dispatch, '
    'других триггеров нет',
    () {
      final on = workflow['on'];
      final triggers = switch (on) {
        final YamlMap map => map.keys.toList(),
        final YamlList list => list.toList(),
        _ => [on],
      };

      expect(triggers, ['workflow_dispatch']);
    },
  );

  test(
    'UC-29-P-01: выкладывается только main — другая ветка останавливает '
    'сборку первым шагом',
    () async {
      final guard = _stepNamed(buildSteps, 'Только main');
      expect(buildSteps.first, same(guard));

      final onMain = await _runStep(guard, {'GITHUB_REF': 'refs/heads/main'});
      expect(onMain.exitCode, 0, reason: '${onMain.stdout}');

      final onTask = await _runStep(guard, {
        'GITHUB_REF': 'refs/heads/task/TASK-7',
      });
      expect(onTask.exitCode, isNot(0));
      expect(onTask.stdout, contains('::error::'));
      expect(onTask.stdout, contains('refs/heads/task/TASK-7'));

      // Собирается коммит, с которого стартовал прогон, а не другая ветка.
      final checkout = _stepUsing(buildSteps, 'actions/checkout');
      expect((checkout['with'] as YamlMap?)?['ref'], isNull);
    },
  );

  test('UC-29-P-01: перед сборкой — анализ и тесты, как в CI', () async {
    final buildIndex = _indexRunning(buildSteps, _buildCommand);
    expect(buildIndex, isNonNegative);

    for (final (command, call) in _checks) {
      final index = _indexRunning(buildSteps, command);
      expect(index, isNonNegative, reason: command);
      expect(index, lessThan(buildIndex), reason: command);

      final (result, calls) = await _runWithFakeTools(buildSteps[index]);
      expect(result.exitCode, 0, reason: '$command: ${result.stderr}');
      if (command == _formatCommand) {
        expect(calls, isNotEmpty);
        for (final formatCall in calls) {
          expect(formatCall.take(call.length), call);
          expect(formatCall.length, greaterThan(call.length));
        }
      } else {
        expect(calls, [call], reason: command);
      }
    }
  });

  test(
    'UC-29-P-02: упала проверка перед сборкой — шаг падает, дальше выкладка '
    'не идёт',
    () async {
      for (final (command, _) in _checks) {
        final step = buildSteps[_indexRunning(buildSteps, command)];

        final (result, calls) = await _runWithFakeTools(step, toolExitCode: 1);

        expect(calls, isNotEmpty, reason: command);
        expect(result.exitCode, isNot(0), reason: command);
      }
    },
  );

  test(
    'UC-29-P-01, UC-38-P-01: сборка по ENT-16 и ENT-17 — release, base href '
    '/yege_wars/, параметры и тестовый вход из секретов',
    () async {
      final step = buildSteps[_indexRunning(buildSteps, _buildCommand)];
      _expectSecretsEnv(step, [..._secretNames, ..._testLoginSecretNames]);

      final (result, calls) = await _runWithFakeTools(
        step,
        env: _buildEnv(
          testUsername: _fakeTestUsername,
          testPassword: _fakeTestPassword,
        ),
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls, [
        _buildCall(
          testUsername: _fakeTestUsername,
          testPassword: _fakeTestPassword,
        ),
      ]);
    },
  );

  test(
    'UC-38-P-02: секреты тестового входа не заданы — проверка секретов '
    'проходит, сборка идёт с пустыми значениями',
    () async {
      // Незаданный секрет GitHub подставляет пустой строкой.
      final env = _buildEnv(testUsername: '', testPassword: '');

      final check = _stepNamed(buildSteps, 'Секреты заданы');
      _expectSecretsEnv(check, _secretNames);
      final checked = await _runStep(check, env);
      expect(checked.exitCode, 0, reason: '${checked.stdout}');

      final step = buildSteps[_indexRunning(buildSteps, _buildCommand)];
      final (result, calls) = await _runWithFakeTools(step, env: env);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls, [_buildCall(testUsername: '', testPassword: '')]);
    },
  );

  test(
    'UC-29-P-02: сборка упала — шаг сборки падает, дальше выкладка не идёт',
    () async {
      final step = buildSteps[_indexRunning(buildSteps, _buildCommand)];

      final (result, calls) = await _runWithFakeTools(
        step,
        env: _buildEnv(
          testUsername: _fakeTestUsername,
          testPassword: _fakeTestPassword,
        ),
        toolExitCode: 1,
      );

      expect(calls, isNotEmpty);
      expect(result.exitCode, isNot(0));
    },
  );

  test('UC-29-P-01: сборка публикуется на GitHub Pages из build/web', () {
    _stepUsing(buildSteps, 'actions/configure-pages');

    final upload = _stepUsing(buildSteps, 'actions/upload-pages-artifact');
    expect((upload['with'] as YamlMap)['path'], 'build/web');
    expect(
      buildSteps.indexOf(upload),
      greaterThan(_indexRunning(buildSteps, _buildCommand)),
    );

    expect(deploy['needs'], 'build');
    expect((deploy['environment'] as YamlMap)['name'], 'github-pages');
    expect(deploy['permissions'], {'pages': 'write', 'id-token': 'write'});
    final deploySteps = (deploy['steps'] as YamlList).cast<YamlMap>();
    expect(deploySteps.single['uses'], startsWith('actions/deploy-pages@'));
  });

  for (final (url, key) in [('', _fakeKey), (_fakeUrl, ''), ('', '')]) {
    final missing = [
      if (url.isEmpty) 'SUPABASE_URL',
      if (key.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    test(
      'UC-29-P-02: не задан ${missing.join(' и ')} — выкладка падает до '
      'сборки, в логе — имя секрета',
      () async {
        final check = _stepNamed(buildSteps, 'Секреты заданы');
        _expectSecretsEnv(check, _secretNames);

        final result = await _runStep(check, {
          'SUPABASE_URL': url,
          'SUPABASE_ANON_KEY': key,
        });

        expect(result.exitCode, isNot(0));
        final log = '${result.stdout}${result.stderr}';
        for (final name in _secretNames) {
          final error = '::error::Секрет $name не задан';
          expect(
            log,
            missing.contains(name) ? contains(error) : isNot(contains(error)),
          );
        }
        expect(log, isNot(contains(_fakeUrl)));
        expect(log, isNot(contains(_fakeKey)));
      },
    );
  }

  test(
    'UC-29-P-02: оба секрета заданы — проверка проходит и значений не '
    'печатает',
    () async {
      final check = _stepNamed(buildSteps, 'Секреты заданы');

      final result = await _runStep(check, {
        'SUPABASE_URL': _fakeUrl,
        'SUPABASE_ANON_KEY': _fakeKey,
      });

      expect(result.exitCode, 0, reason: '${result.stdout}');
      final log = '${result.stdout}${result.stderr}';
      expect(log, isNot(contains(_fakeUrl)));
      expect(log, isNot(contains(_fakeKey)));
    },
  );

  test('UC-29-P-02: секреты проверяются до checkout, проверок и сборки', () {
    final check = buildSteps.indexOf(_stepNamed(buildSteps, 'Секреты заданы'));

    expect(
      check,
      lessThan(buildSteps.indexOf(_stepUsing(buildSteps, 'actions/checkout'))),
    );
    expect(check, lessThan(_indexRunning(buildSteps, 'flutter pub get')));
    expect(check, lessThan(_indexRunning(buildSteps, _buildCommand)));
  });

  test(
    'UC-29-P-02: упавшая сборка не публикуется — публикация только в deploy '
    'после build',
    () {
      expect(deploy['needs'], 'build');
      for (final job in [build, deploy]) {
        expect(job['if'], isNull);
        expect(job['continue-on-error'], isNull);
      }
      for (final step in buildSteps) {
        expect(step['if'], isNull, reason: '${step['name'] ?? step['uses']}');
        expect(
          step['continue-on-error'],
          isNull,
          reason: '${step['name'] ?? step['uses']}',
        );
      }
      expect(
        buildSteps.where(
          (step) => '${step['uses']}'.startsWith('actions/deploy-pages@'),
        ),
        isEmpty,
      );
    },
  );
}

/// Шаг с именем [name].
YamlMap _stepNamed(List<YamlMap> steps, String name) =>
    steps.singleWhere((step) => step['name'] == name);

/// Шаг, который вызывает action [action] любой версии.
YamlMap _stepUsing(List<YamlMap> steps, String action) =>
    steps.singleWhere((step) => '${step['uses']}'.startsWith('$action@'));

/// Номер шага, чья команда содержит [command]; `-1`, если такого нет.
///
/// Пробелы и переносы строк в команде сводятся к одному пробелу: длинные
/// команды записаны в YAML свёрнутыми строками.
int _indexRunning(List<YamlMap> steps, String command) => steps.indexWhere(
  (step) =>
      '${step['run'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').contains(command),
);

/// Проверяет, что `env` шага — ровно секреты GitHub [names] под теми же
/// именами.
void _expectSecretsEnv(YamlMap step, List<String> names) {
  expect(step['env'], {
    for (final name in names) name: '\${{ secrets.$name }}',
  });
}

/// Окружение шага сборки: обязательные секреты — поддельные, секреты
/// тестового входа — [testUsername] и [testPassword].
Map<String, String> _buildEnv({
  required String testUsername,
  required String testPassword,
}) => {
  'SUPABASE_URL': _fakeUrl,
  'SUPABASE_ANON_KEY': _fakeKey,
  'TEST_LOGIN_USERNAME': testUsername,
  'TEST_LOGIN_PASSWORD': testPassword,
};

/// Вызов `flutter`, который делает шаг сборки с окружением [_buildEnv].
List<String> _buildCall({
  required String testUsername,
  required String testPassword,
}) => [
  'flutter',
  'build',
  'web',
  '--release',
  '--base-href',
  '/yege_wars/',
  '--dart-define=SUPABASE_URL=$_fakeUrl',
  '--dart-define=SUPABASE_ANON_KEY=$_fakeKey',
  '--dart-define=TEST_LOGIN_USERNAME=$testUsername',
  '--dart-define=TEST_LOGIN_PASSWORD=$testPassword',
];

/// Запускает команду шага так же, как GitHub на Linux: при `shell: bash` —
/// `bash --noprofile --norc -eo pipefail`, без `shell` — `bash -e`.
///
/// [env] дополняет окружение теста; [path] ставится в начало `PATH`.
Future<ProcessResult> _runStep(
  YamlMap step,
  Map<String, String> env, {
  String? path,
}) async {
  final dir = await Directory.systemTemp.createTemp('deploy_step');
  addTearDown(() => dir.delete(recursive: true));
  final script = File('${dir.path}/step.sh')
    ..writeAsStringSync(step['run'] as String);
  final flags = step['shell'] == 'bash'
      ? ['--noprofile', '--norc', '-eo', 'pipefail']
      : ['-e'];

  return Process.run(
    'bash',
    [...flags, script.path],
    environment: {
      ...env,
      if (path != null) 'PATH': '$path:${Platform.environment['PATH']}',
    },
  );
}

/// Запускает шаг с поддельными `flutter` и `dart` в начале `PATH`.
///
/// Поддельная программа на каждый вызов печатает строку — своё имя и
/// аргументы через табуляцию — и завершается с кодом [toolExitCode].
/// Возвращает итог шага и вызовы по порядку.
Future<(ProcessResult, List<List<String>>)> _runWithFakeTools(
  YamlMap step, {
  Map<String, String> env = const {},
  int toolExitCode = 0,
}) async {
  final bin = await Directory.systemTemp.createTemp('fake_tools');
  addTearDown(() => bin.delete(recursive: true));
  for (final tool in ['flutter', 'dart']) {
    final file = File('${bin.path}/$tool')
      ..writeAsStringSync(
        '#!/bin/sh\n'
        'printf "%s" "\${0##*/}"\n'
        r'for arg in "$@"; do printf "\t%s" "$arg"; done'
        '\n'
        r'printf "\n"'
        '\n'
        'exit $toolExitCode\n',
      );
    await Process.run('chmod', ['+x', file.path]);
  }

  final result = await _runStep(step, env, path: bin.path);
  final calls = const LineSplitter()
      .convert('${result.stdout}')
      .map((line) => line.split('\t'))
      .toList();
  return (result, calls);
}
