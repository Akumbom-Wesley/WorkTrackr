import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/worktrackr_error_view.dart';
import '../employees/widgets/employee_search_bar.dart';
import 'model/hr_onboarding_models.dart';
import 'providers/hr_onboarding_providers.dart';
import 'widgets/onboarding_employee_row.dart';
import 'widgets/onboarding_stats_grid.dart';

/// Onboarding Management — distinct from the Employees screen. Stat row,
/// search, and a scrolling pending-verification list with per-row stub
/// email actions. The previous version also carried a static "Execution
/// Validation Protocol" stepper and a "Security-First Culture" messaging
/// card; both were purely presentational (no backing data, non-interactive)
/// and were removed per explicit product decision to cut screen length and
/// keep the screen focused on its one real job: triaging pending people.
/// Pagination was also removed — the entries list renders directly inside
/// the outer scroll view, consistent with how the Employees screen handles
/// its list, rather than a separate prev/next-paged sub-widget.
class HrOnboardingScreen extends ConsumerStatefulWidget {
  const HrOnboardingScreen({super.key});

  @override
  ConsumerState<HrOnboardingScreen> createState() => _HrOnboardingScreenState();
}

class _HrOnboardingScreenState extends ConsumerState<HrOnboardingScreen> {
  bool _isSendingBulk = false;
  final Set<String> _sendingIds = {};

  Future<void> _handleBulkSend() async {
    if (_isSendingBulk) return;
    setState(() => _isSendingBulk = true);
    try {
      await ref.read(hrOnboardingProvider.notifier).sendBulkEmails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk onboarding emails sent successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send bulk emails: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingBulk = false);
    }
  }

  Future<void> _handleRowAction(OnboardingEntry entry) async {
    final id = entry.employee.erpnextEmployeeId;
    if (_sendingIds.contains(id)) return;
    
    setState(() => _sendingIds.add(id));
    try {
      if (entry.emailStatus == OnboardingEmailStatus.notSent) {
        await ref.read(hrOnboardingProvider.notifier).sendEmail(id);
      } else {
        await ref.read(hrOnboardingProvider.notifier).resendEmail(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onboarding email sent to ${entry.employee.fullName}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email to ${entry.employee.fullName}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(hrOnboardingProvider);
    final filteredAsync = ref.watch(hrFilteredOnboardingEntriesProvider);
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
          'Onboarding',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(hrOnboardingProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => WorkTrackrErrorView(
          title: 'Could not load onboarding data',
          message: 'Check your connection and try again.',
          onRetry: () => ref.read(hrOnboardingProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () => ref.read(hrOnboardingProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Onboarding Management',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage credential distribution and verification progress.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSendingBulk ? null : _handleBulkSend,
                  icon: _isSendingBulk
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.forward_to_inbox_rounded, size: 18),
                  label: Text(_isSendingBulk ? 'Sending...' : 'Send Emails to All Pending'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OnboardingStatsGrid(stats: data.stats),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Verification',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.entries.length} awaiting setup',
                          style: AppTextStyles.labelSm.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              EmployeeSearchBar(
                queryProvider: hrOnboardingSearchQueryProvider,
                hintText:
                    'Search pending employees by name or ID...',
              ),
              const SizedBox(height: 10),
              filteredAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No pending employees match your search.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final entry in entries) ...[
                        OnboardingEmployeeRow(
                          entry: entry,
                          isProcessing: _sendingIds.contains(entry.employee.erpnextEmployeeId),
                          onAction: () => _handleRowAction(entry),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
