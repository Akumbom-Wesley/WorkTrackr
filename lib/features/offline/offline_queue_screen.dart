import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
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

  void _reload() {
    setState(() => _items = CheckinQueue.instance.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        title: Text(
          'Offline Queue',
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimary),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: AppColors.secondary,
        child: _items.isEmpty ? _buildEmpty() : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  size: 40,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'All synced',
                style: AppTextStyles.headlineMd
                    .copyWith(color: AppColors.onBackground),
              ),
              const SizedBox(height: 8),
              Text(
                'No pending check-ins in the queue.',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(
                label: isIn ? 'CLOCK IN' : 'CLOCK OUT',
                color: isIn ? AppColors.secondary : AppColors.securityError,
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
            color: AppColors.onBackground,
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
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSm.copyWith(
              color: color ?? AppColors.onSurfaceVariant,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
