# COMP-17: Сводка и прогресс по номерам

## Варианты

Общая сводка «Решено {solved} из {total}» и строки с названием номера,
числовой подписью «{solved} / {total}» и штатным `LinearProgressIndicator`.
Задачи без номера имеют подпись «Без номера КЕГЭ» и идут последними.
При отсутствии опубликованных задач общая сводка показывает 0 из 0,
вместо строк показан текст пустого состояния. При нулевом знаменателе
индикатор использует значение 0.

## Состояния

Компонент показывает загруженные данные. На этапе загрузки экран показывает
штатный `CircularProgressIndicator`. Прогресс имеет семантическую подпись
с решённым и общим количеством. Числа доступны текстом.

## Токены

- Цвет поверхности — `AppColors.surface`, [TOKEN-7](TOKEN-7-COLOR.md#surface).
- Текст — `AppColors.textPrimary`, [TOKEN-7](TOKEN-7-COLOR.md#text-primary).
- Вторичный текст — `AppColors.textSecondary`, [TOKEN-7](TOKEN-7-COLOR.md#text-secondary).
- Заполнение индикатора — `AppColors.accent`, [TOKEN-7](TOKEN-7-COLOR.md#accent).
- Типографика — `AppTypography.textTheme`, [TOKEN-2](TOKEN-2-TYPOGRAPHY.md#text-theme),
  `titleLarge` для сводки, `bodyMedium` для строки.
- Внутренний отступ — `AppSpacing.lg`, [TOKEN-3](TOKEN-3-SPACING.md#lg).
- Зазор между строками — `AppSpacing.lg`, [TOKEN-3](TOKEN-3-SPACING.md#lg).
- Между подписью и индикатором — `AppSpacing.sm`, [TOKEN-3](TOKEN-3-SPACING.md#sm).
- Радиус карточки — `AppRadius.lg`, [TOKEN-4](TOKEN-4-RADIUS.md#lg).
