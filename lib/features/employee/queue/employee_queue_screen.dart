import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../offline/models/queued_checkin.dart';
import '../../offline/queue/checkin_queue.dart';
import '../../offline/sync/sync_service.dart';
import '../../offline/providers/offline_providers.dart';

class EmployeeQueueScreen extends ConsumerStatefulWidget {
  const EmployeeQueueScreen({super.key});

  @override
  ConsumerState<EmployeeQueueScreen> createState() =>
      _EmployeeQueueScreenState();
}

class _EmployeeQueueScreenState extends ConsumerState<EmployeeQueueScreen> {
  List<QueuedCheckin> _items = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await CheckinQueue.instance.getAll();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    await SyncService.instance.syncNow();
    ref.invalidate(queueCountProvider);
    await _reload();
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _items.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _QueueSummaryHeader(items: _items),
            ),
            if (!isEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'PENDING ENTRIES',
                    style: AppTextStyles.labelXs.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _QueueEntryCard(
                        item: _items[i],
                        index: i + 1,
                        total: _items.length,
                      ),
                    ),
                    childCount: _items.length,
                  ),
                ),
              ),
            ] else
              const SliverFillRemaining(child: _EmptyState()),
          ],
        ),
      ),
      bottomNavigationBar: isEmpty
          ? null
          : _SyncBar(
              count: _items.length,
              syncing: _syncing,
              onSync: _sync,
            ),
    );
  }
}

// ── Summary header ─────────────────────────────────────────────────────────

class _QueueSummaryHeader extends StatelessWidget {
  const _QueueSummaryHeader({required this.items});
  final List<QueuedCheckin> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final oldest = items.first.queuedAt;
    final age = DateTime.now().difference(oldest);
    final ageLabel = age.inHours > 0
        ? '${age.inHours}h ${age.inMinutes.remainder(60)}m ago'
        : '${age.inMinutes}m ago';

    final priority = items.length >= 5
        ? ('Critical', AppColors.securityError)
        : items.length >= 3
            ? ('High', AppColors.securityWarning)
            : ('Normal', cs.secondary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _MetricCard(
                label: 'Pending',
                value: items.length.toString().padLeft(2, '0'),
                icon: Icons.pending_actions_rounded,
                color: cs.onTertiaryContainer,
                context: context,
              ),
              const SizedBox(width: 10),
              _MetricCard(
                label: 'Oldest',
                value: ageLabel,
                icon: Icons.schedule_rounded,
                color: AppColors.securityWarning,
                context: context,
              ),
              const SizedBox(width: 10),
              _MetricCard(
                label: 'Priority',
                value: priority.$1,
                icon: Icons.flag_rounded,
                color: priority.$2,
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.context,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 16,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelXs.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Entry card ─────────────────────────────────────────────────────────────

class _QueueEntryCard extends StatelessWidget {
  const _QueueEntryCard({
    required this.item,
    required this.index,
    required this.total,
  });
  final QueuedCheckin item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = item.payload;
    final isIn = (p['log_type'] as String? ?? 'IN') == 'IN';
    final lat = (p['gps_lat_smoothed'] as num?)?.toStringAsFixed(4) ?? '--';
    final lng = (p['gps_lng_smoothed'] as num?)?.toStringAsFixed(4) ?? '--';
    final ssid = p['wifi_ssid'] as String? ?? '';
    final band = p['wifi_band'] as String? ?? '';
    final tsRaw = p['timestamp_device'] as String?;
    final dt = tsRaw != null ? DateTime.parse(tsRaw).toLocal() : null;

    final cs = Theme.of(context).colorScheme;
    final typeColor = isIn ? cs.secondary : cs.onTertiaryContainer;
    final typeLabel = isIn ? 'Clock In' : 'Clock Out';
    final typeIcon = isIn ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, size: 16, color: typeColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                    if (dt != null)
                      Text(
                        _fmtDateTime(dt),
                        style: AppTextStyles.labelSm.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.securityWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.securityWarning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$index / $total',
                    style: AppTextStyles.labelXs.copyWith(
                      color: AppColors.securityWarning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'GPS',
                  value: '$lat° N, $lng° W',
                ),
                if (ssid.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.wifi_rounded,
                    label: 'Wi-Fi',
                    value: band.isNotEmpty ? '$ssid ($band)' : ssid,
                  ),
                ],
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'Verified',
                  value: 'Biometric + GPS',
                  valueColor: cs.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $time';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.labelSm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.labelSm.copyWith(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Sync bar ───────────────────────────────────────────────────────────────

class _SyncBar extends StatelessWidget {
  const _SyncBar({
    required this.count,
    required this.syncing,
    required this.onSync,
  });
  final int count;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton(
          onPressed: syncing ? null : onSync,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: syncing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Syncing...',
                      style: AppTextStyles.button,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sync Now  (${count.toString().padLeft(2, '0')} queued)',
                      style: AppTextStyles.button,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_done_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Synced',
            style: AppTextStyles.headlineMd.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending check-ins in the queue.',
            style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
