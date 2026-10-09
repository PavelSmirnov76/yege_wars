<!-- Производный файл: собирает `python3 -m sdlc_tool views`, руками не править. -->

# Индекс: `3-design/design-system/`

| Id | Название | Ссылается на | Где реализован |
|---|---|---|---|
| [TOKEN-2](TOKEN-2-TYPOGRAPHY.md) | Типографика | — | [`lib/app/theme/app_typography.dart`](../../../lib/app/theme/app_typography.dart) |
| [TOKEN-3](TOKEN-3-SPACING.md) | Отступы | — | [`lib/app/theme/app_spacing.dart`](../../../lib/app/theme/app_spacing.dart) |
| [TOKEN-4](TOKEN-4-RADIUS.md) | Радиусы | — | [`lib/app/theme/app_radius.dart`](../../../lib/app/theme/app_radius.dart) |
| [TOKEN-5](TOKEN-5-BREAKPOINT.md) | Брейкпоинты | — | [`lib/app/theme/app_breakpoints.dart`](../../../lib/app/theme/app_breakpoints.dart) |
| [TOKEN-6](TOKEN-6-TAP.md) | Тап-цели и фокус | — | [`lib/app/theme/app_theme.dart`](../../../lib/app/theme/app_theme.dart) |
| [TOKEN-7](TOKEN-7-COLOR.md) | Цвета | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) | [`lib/app/theme/app_colors.dart`](../../../lib/app/theme/app_colors.dart) |
| [COMP-1](COMP-1-AUTH-FORM-CARD.md) | Карточка формы | [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-4](TOKEN-4-RADIUS.md), [TOKEN-1](obsolete/TOKEN-1-COLOR.md) | [`lib/features/auth/presentation/widgets/auth_form_card.dart`](../../../lib/features/auth/presentation/widgets/auth_form_card.dart) |
| [COMP-2](COMP-2-AUTH-MESSAGE.md) | Сообщение формы | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-3](TOKEN-3-SPACING.md) | [`lib/features/auth/presentation/widgets/auth_message.dart`](../../../lib/features/auth/presentation/widgets/auth_message.dart) |
| [COMP-3](COMP-3-SUBMIT-BUTTON.md) | Кнопка отправки | [TOKEN-6](TOKEN-6-TAP.md), [TOKEN-1](obsolete/TOKEN-1-COLOR.md) | [`lib/features/auth/presentation/widgets/auth_submit_button.dart`](../../../lib/features/auth/presentation/widgets/auth_submit_button.dart) |
| [COMP-4](COMP-4-NAVIGATION.md) | Навигация приложения | [TOKEN-5](TOKEN-5-BREAKPOINT.md) | [`lib/app/router/app_shell.dart`](../../../lib/app/router/app_shell.dart), [`lib/core/widgets/adaptive_navigation_scaffold.dart`](../../../lib/core/widgets/adaptive_navigation_scaffold.dart) |
| [COMP-5](COMP-5-PROBLEM-CARD.md) | Карточка задачи | [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/features/tasks/presentation/widgets/task_card.dart`](../../../lib/features/tasks/presentation/widgets/task_card.dart), [`test/app/theme/card_ink_test.dart`](../../../test/app/theme/card_ink_test.dart) |
| [COMP-6](COMP-6-DIFFICULTY-BADGE.md) | Метка сложности | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-4](TOKEN-4-RADIUS.md), [TOKEN-3](TOKEN-3-SPACING.md) | [`lib/features/tasks/presentation/widgets/difficulty_badge.dart`](../../../lib/features/tasks/presentation/widgets/difficulty_badge.dart) |
| [COMP-7](COMP-7-PROGRESS-BADGE.md) | Метка состояния решения | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-3](TOKEN-3-SPACING.md) | [`lib/features/tasks/presentation/widgets/progress_badge.dart`](../../../lib/features/tasks/presentation/widgets/progress_badge.dart) |
| [COMP-8](COMP-8-CODE-EDITOR.md) | Поле кода | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/features/editor/presentation/widgets/code_editor.dart`](../../../lib/features/editor/presentation/widgets/code_editor.dart), [`lib/features/editor/presentation/widgets/python_editing_controller.dart`](../../../lib/features/editor/presentation/widgets/python_editing_controller.dart) |
| [COMP-9](COMP-9-CONSOLE.md) | Консоль | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/features/editor/presentation/widgets/console_view.dart`](../../../lib/features/editor/presentation/widgets/console_view.dart) |
| [COMP-10](COMP-10-VERDICT.md) | Вердикт | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/features/submissions/presentation/widgets/verdict_banner.dart`](../../../lib/features/submissions/presentation/widgets/verdict_banner.dart) |
| [COMP-11](COMP-11-CODE-BLOCK.md) | Блок кода | [COMP-8](COMP-8-CODE-EDITOR.md), [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/core/markdown/code_block.dart`](../../../lib/core/markdown/code_block.dart) |
| [COMP-12](COMP-12-ERROR-RETRY.md) | Ошибка с повтором | [TOKEN-3](TOKEN-3-SPACING.md) | [`lib/features/reference/presentation/widgets/reference_error_view.dart`](../../../lib/features/reference/presentation/widgets/reference_error_view.dart) |
| [COMP-13](COMP-13-ARTICLE-META.md) | Сведения о статье | [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md) | [`lib/features/reference/presentation/widgets/article_meta.dart`](../../../lib/features/reference/presentation/widgets/article_meta.dart) |
| [COMP-14](COMP-14-ARTICLE-CARD.md) | Карточка статьи | [COMP-13](COMP-13-ARTICLE-META.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-1](obsolete/TOKEN-1-COLOR.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/features/reference/presentation/widgets/article_card.dart`](../../../lib/features/reference/presentation/widgets/article_card.dart), [`test/app/theme/card_ink_test.dart`](../../../test/app/theme/card_ink_test.dart) |
| [COMP-16](COMP-16-MARKDOWN.md) | Разметка | [COMP-15](obsolete/COMP-15-MARKDOWN.md), [TOKEN-2](TOKEN-2-TYPOGRAPHY.md), [TOKEN-3](TOKEN-3-SPACING.md), [TOKEN-7](TOKEN-7-COLOR.md), [COMP-11](COMP-11-CODE-BLOCK.md), [TOKEN-4](TOKEN-4-RADIUS.md) | [`lib/core/markdown/app_markdown.dart`](../../../lib/core/markdown/app_markdown.dart) |

## К пересмотру

| Id | Ссылается на похороненное |
|---|---|
| [COMP-1](COMP-1-AUTH-FORM-CARD.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-2](COMP-2-AUTH-MESSAGE.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-3](COMP-3-SUBMIT-BUTTON.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-5](COMP-5-PROBLEM-CARD.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-6](COMP-6-DIFFICULTY-BADGE.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-7](COMP-7-PROGRESS-BADGE.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-8](COMP-8-CODE-EDITOR.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-9](COMP-9-CONSOLE.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-10](COMP-10-VERDICT.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-11](COMP-11-CODE-BLOCK.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-13](COMP-13-ARTICLE-META.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |
| [COMP-14](COMP-14-ARTICLE-CARD.md) | [TOKEN-1](obsolete/TOKEN-1-COLOR.md) |

## Похоронены

| Id | Название | Заменён |
|---|---|---|
| [TOKEN-1](obsolete/TOKEN-1-COLOR.md) | Цвета | [TOKEN-7](TOKEN-7-COLOR.md) |
| [COMP-15](obsolete/COMP-15-MARKDOWN.md) | Разметка | [COMP-16](COMP-16-MARKDOWN.md) |
