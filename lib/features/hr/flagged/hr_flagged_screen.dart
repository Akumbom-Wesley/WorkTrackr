import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/worktrackr_empty_state.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/worktrackr_error_view.dart';
import 'model/hr_flagged_models.dart';
import 'providers/hr_flagged_providers.dart';

/// Standalone route version — owns its own Scaffold + AppBar.
/// Used when navigating via the drawer or a deep-link route.
/// The nav-shell tab uses [HrFlaggedTabView] instead (no Scaffold).
class HrFlaggedScreen extends ConsumerWidget {
  const HrFlaggedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Flagged Records',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
        ),
        centerTitle: true,
      ),
      body: const HrFlaggedTabView(),
    );
  }
}

/// Tab-body version — no Scaffold/AppBar.
/// Used as the PersistentTabConfig screen inside WorkTrackrNavShell,
/// which already provides the outer Scaffold + WorkTrackrAppBar.
///
/// Offline-first: cache-then-network via HrFlaggedRepository.watchFlagged().
/// Cached list surfaces immediately; fresh data replaces it once the network
/// call resolves. If offline with a prior cache, stale list stays silently.
/// If offline with no prior cache, WorkTrackrErrorView is shown with retry.
class HrFlaggedTabView extends ConsumerWidget {
  const HrFlaggedTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flaggedAsync = ref.watch(hrFlaggedProvider);
    final showResolved = ref.watch(hrShowResolvedProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _Chip(
                  label: 'Pending',
                  isActive: !showResolved,
                  onTap: () {
                    ref.read(hrShowResolvedProvider.notifier).state = false;
                    ref.read(hrFlaggedProvider.notifier).refresh();
                  },
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'All',
                  isActive: showResolved,
                  onTap: () {
                    ref.read(hrShowResolvedProvider.notifier).state = true;
                    ref.read(hrFlaggedProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: flaggedAsync.when(
              loading: () => const _Shimmer(),
              error: (_, __) => WorkTrackrErrorView(
                title: 'Could not load flagged records',
                message: 'Check your connection and try again.',
                onRetry: () =>
                    ref.read(hrFlaggedProvider.notifier).refresh(),
              ),
              data: (records) => records.isEmpty
                  ? const _Empty()
                  : RefreshIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      onRefresh: () =>
                          ref.read(hrFlaggedProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: records.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _FlaggedTile(
                          record: records[i],
                          onResolve: records[i].resolved
                              ? null
                              : () => ref
                                  .read(hrFlaggedProvider.notifier)
                                  .resolve(records[i].id),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────

class _FlaggedTile extends StatelessWidget {
  const _FlaggedTile({required this.record, this.onResolve});
  final FlaggedRecord record;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final flagColor = record.resolved
        ? AppColors.securitySuccess
        : AppColors.securityWarning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: flagColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.employeeName,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(resolved: record.resolved),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record.erpnextEmployeeId,
            style: AppTextStyles.labelXs
                .copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeChip(flagType: record.flagType),
              const SizedBox(width: 8),
              Text(
                record.date,
                style: AppTextStyles.labelXs
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.notes!,
              style: AppTextStyles.bodyMd.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (onResolve != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Mark as Resolved'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.securitySuccess,
                  side: BorderSide(
                      color: AppColors.securitySuccess
                          .withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.resolved});
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final color =
        resolved ? AppColors.securitySuccess : AppColors.securityWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        resolved ? 'Resolved' : 'Pending',
        style: AppTextStyles.labelXs.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.flagType});
  final String flagType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.securityError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        flagType.replaceAll('_', ' '),
        style: AppTextStyles.labelXs.copyWith(
          color: AppColors.securityError,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Support widgets ────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cs.primary : cs.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();
  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const WorkTrackrEmptyState(
      title: 'All Good',
      message: 'No flagged activities found for this criteria.',
      icon: Icons.check_circle_outline_rounded,
    );
  }
}
