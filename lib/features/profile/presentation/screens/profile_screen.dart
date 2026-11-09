import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yege_wars/app/router/app_routes.dart';
import 'package:yege_wars/app/theme/app_breakpoints.dart';
import 'package:yege_wars/app/theme/app_colors.dart';
import 'package:yege_wars/app/theme/app_radius.dart';
import 'package:yege_wars/app/theme/app_spacing.dart';
import 'package:yege_wars/core/error/failure.dart';
import 'package:yege_wars/core/utils/l10n_ext.dart';
import 'package:yege_wars/features/auth/domain/entities/user_role.dart';
import 'package:yege_wars/features/auth/presentation/controllers/auth_controller.dart';
import 'package:yege_wars/features/profile/domain/progress.dart';
import 'package:yege_wars/features/profile/presentation/progress_providers.dart';
import 'package:yege_wars/features/reference/presentation/widgets/reference_error_view.dart';
import 'package:yege_wars/features/submissions/presentation/widgets/attempts_list.dart';

/// Экран профиля. Реализует UC-4, UC-13, UC-41 и UC-42.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    final failure = result.failureOrNull;
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(authControllerProvider).profileOrNull;
    final role = profile?.role == UserRole.admin
        ? l10n.profileRoleAdmin
        : l10n.profileRoleStudent;
    final progress = profile == null
        ? null
        : ref.watch(profileProgressProvider(profile.id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              profile?.username ?? l10n.navProfile,
              style: theme.textTheme.titleLarge,
            ),
            if (profile != null)
              Text(
                '${l10n.profileRoleLabel}: $role',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.xl),
            if (progress == null || progress.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (progress.hasError)
              ReferenceErrorView(
                error: progress.error is Failure
                    ? progress.error!
                    : DatabaseFailure(message: l10n.profileProgressLoadError),
                onRetry: () =>
                    ref.invalidate(profileProgressProvider(profile!.id)),
              )
            else if (progress.value case final summary?)
              LayoutBuilder(
                builder: (context, constraints) {
                  final left = _ProgressCard(summary: summary);
                  final right = _AttemptsCard(attempts: summary.attempts);
                  if (MediaQuery.sizeOf(context).width <=
                      AppBreakpoints.tabletMax) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        left,
                        const SizedBox(height: AppSpacing.xl),
                        right,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: right),
                    ],
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => unawaited(_signOut(context, ref)),
                icon: const Icon(Icons.logout),
                label: Text(l10n.profileSignOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сводка и прогресс по номерам: COMP-17.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});
  final ProgressSummary summary;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.profileSolvedTitle, style: theme.textTheme.titleMedium),
          Text(
            l10n.profileSolvedSummary(summary.solved, summary.total),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.profileProgressTitle, style: theme.textTheme.titleMedium),
          if (summary.byNumber.isEmpty) Text(l10n.profileEmptyTasks),
          for (final row in summary.byNumber) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.number == null
                        ? l10n.profileNoEgeNumber
                        : l10n.profileEgeNumber(row.number!),
                  ),
                ),
                Text(l10n.profileProgressCount(row.solved, row.total)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: row.total == 0 ? 0 : row.solved / row.total,
              semanticsLabel: l10n.profileProgressCount(row.solved, row.total),
            ),
          ],
        ],
      ),
    );
  }
}

/// Последние попытки: COMP-18.
class _AttemptsCard extends StatelessWidget {
  const _AttemptsCard({required this.attempts});
  final List<RecentAttempt> attempts;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileRecentAttemptsTitle,
            style: theme.textTheme.titleMedium,
          ),
          if (attempts.isEmpty) Text(l10n.profileEmptyAttempts),
          for (final attempt in attempts)
            InkWell(
              onTap: () => context.goNamed(
                AppRoutes.taskName,
                pathParameters: {AppRoutes.slugParam: attempt.slug},
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(attempt.title, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                          attempt.number == null
                              ? l10n.profileNoEgeNumber
                              : l10n.profileEgeNumber(attempt.number!),
                        ),
                        Text(
                          attempt.correct
                              ? l10n.profileAttemptCorrect
                              : l10n.profileAttemptWrong,
                          style: TextStyle(
                            color: attempt.correct
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        Text(attemptTimeLabel(attempt.createdAt.toLocal())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );
}
