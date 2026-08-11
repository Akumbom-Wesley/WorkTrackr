import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/worktrackr_empty_state.dart';
import '../../core/constants/app_text_styles.dart';
import 'models/queued_checkin.dart';
import 'queue/checkin_queue.dart';

class OfflineQueueScreen extends ConsumerStatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  ConsumerState<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends ConsumerState<OfflineQueueScreen> {
  List<QueuedCheckin> _items = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Offline Queue',
          style: AppTextStyles.headlineMd.copyWith(color: Theme.of(context).colorScheme.onPrimary),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: () async => _reload(),
        child: _items.isEmpty ? _buildEmpty() : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return const CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: WorkTrackrEmptyState(
            title: 'All synced',
            message: 'No pending check-ins in the queue.',
            icon: Icons.cloud_done_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _QueueCard(item: _items[i]),
    );
  }
}

// ── Queue card ─────────────────────────────────────────────────────────────

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});
  final QueuedCheckin item;

  @override
  Widget build(BuildContext context) {
    final p = item.payload;
    final isIn = (p['log_type'] as String? ?? 'IN') == 'IN';
    final lat = p['gps_lat_smoothed'] as String? ?? '--';
    final lng = p['gps_lng_smoothed'] as String? ?? '--';
    final band = p['wifi_band'] as String? ?? 'UNAVAILABLE';
    final ssid = p['wifi_ssid'] as String? ?? '';
    final tsRaw = p['timestamp_device'] as String?;
    final dt = tsRaw != null ? DateTime.parse(tsRaw).toLocal() : null;
    final time = dt != null ? _fmt(dt, time: true) : '--';
    final date = dt != null ? _fmt(dt, time: false) : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(
                label: isIn ? 'CLOCK IN' : 'CLOCK OUT',
                color: isIn ? Theme.of(context).colorScheme.secondary : AppColors.securityError,
              ),
              const Spacer(),
              _Chip(
                label: 'Pending',
                color: AppColors.securityWarning,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(Icons.calendar_today_rounded, date),
          const SizedBox(height: 6),
          _InfoRow(
            Icons.access_time_rounded,
            time,
            bold: true,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 6),
          _InfoRow(Icons.location_on_rounded, '$lat, $lng'),
          const SizedBox(height: 6),
          _InfoRow(
            Icons.wifi_rounded,
            ssid.isNotEmpty ? '$ssid ($band)' : band,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt, {required bool time}) {
    if (time) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelXs
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text, {this.bold = false, this.color});
  final IconData icon;
  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSm.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
