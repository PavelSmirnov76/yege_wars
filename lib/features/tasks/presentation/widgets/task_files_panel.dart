import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/app/theme/app_typography.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/tasks/domain/entities/task_file.dart';
import 'package:yege_wars/l10n/gen/app_localizations.dart';

/// Читаемый размер файла: байты до килобайта, дальше — килобайты.
String fileSizeLabel(int bytes, AppLocalizations l10n) {
  const bytesInKilobyte = 1024;
  if (bytes < bytesInKilobyte) {
    return l10n.unitBytes(bytes);
  }
  final kilobytes = bytes / bytesInKilobyte;
  return l10n.unitKilobytes(
    kilobytes >= 100
        ? kilobytes.round().toString()
        : kilobytes.toStringAsFixed(1),
  );
}

/// Файлы данных задачи: размер, первые строки и копирование.
///
/// Файл открывается программой ученика по имени, поэтому имя показывается
/// как есть. Скачивание файла появится вместе с редактором.
class TaskFilesPanel extends StatelessWidget {
  /// Создаёт панель для файлов [files].
  const TaskFilesPanel({required this.files, super.key});

  /// Сколько строк показывать в предпросмотре.
  static const int _previewLines = 5;

  /// Файлы задачи.
  final List<TaskFile> files;

  /// Первые строки файла.
  static String previewOf(String content) =>
      content.split('\n').take(_previewLines).join('\n');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (files.isEmpty) {
      return Text(
        l10n.taskFilesEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final file in files)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ExpansionTile(
              title: Text(file.filename, style: AppTypography.code()),
              subtitle: Text(fileSizeLabel(file.sizeBytes, l10n)),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.taskFilePreview,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.codeBackground,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      previewOf(file.content),
                      style: AppTypography.code(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, file),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(l10n.taskFileCopy),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Копирует содержимое файла в буфер обмена.
  Future<void> _copy(BuildContext context, TaskFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.taskFileCopied;
    await Clipboard.setData(ClipboardData(text: file.content));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
