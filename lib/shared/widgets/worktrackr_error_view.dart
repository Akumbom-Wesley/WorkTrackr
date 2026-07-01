import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

/// Shared full-screen error state used across the app whenever a
/// cache-then-network stream has nothing cached and the network call
/// fails. Replaces the per-screen duplicated error widgets.
///
/// Always sizes the Retry button explicitly (SizedBox) rather than
/// letting it size to content — prevents it stretching full-width
/// when an ancestor (e.g. a stretching Column or sliver) imposes
/// tighter width constraints than expected.
class WorkTrackrErrorView extends StatelessWidget {
  const WorkTrackrErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Could not load data',
  });

  /// Short headline, e.g. "Could not load flagged records."
  final String title;

  /// Friendlier explanation shown below the title.
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: cs.onErrorContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
