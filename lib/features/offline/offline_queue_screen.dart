import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'models/queued_checkin.dart';
import 'providers/offline_providers.dart';
import 'queue/checkin_queue.dart';
import 'sync/sync_service.dart';

class OfflineQueueScreen extends ConsumerStatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  ConsumerState<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends ConsumerState<OfflineQueueScreen> {
  List<QueuedCheckin> _items = [];
  bool _syncing = false;
  String? _lastSyncMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _items = CheckinQueue.instance.getAll());
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() { _syncing = true; _lastSyncMessage = null; });
    final result = await SyncService.instance.syncNow();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      switch (result) {
        case SyncResult.success:
          _lastSyncMessage = 'All records synced successfully.';
        case SyncResult.empty:
          _lastSyncMessage = 'Queue is already empty.';
        case SyncResult.failed:
          _lastSyncMessage = 'Sync failed. Check your connection and retry.';
        case SyncResult.skipped:
          _lastSyncMessage = 'Sync already in progress.';
      }
      _reload();
    });
    ref.invalidate(queueCountProvider);
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
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: _syncing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              onPressed: _syncing ? null : _syncNow,
              tooltip: 'Sync now',
            ),
        ],
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
                width: 80, height: 80,
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
              Text('All synced',
                  style: AppTextStyles.headlineMd
                      .copyWith(color: AppColors.onBackground)),
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
    return Column(
      children: [
        // Pending banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.securityWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.securityWarning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded,
                  color: AppColors.securityWarning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_items.length} record${_items.length == 1 ? '' : 's'} pending sync',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.securityWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sync result message
        if (_lastSyncMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _lastSyncMessage!.contains('success')
                  ? AppColors.securitySuccess.withValues(alpha: 0.1)
                  : AppColors.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _lastSyncMessage!,
              style: AppTextStyles.labelSm.copyWith(
                color: _lastSyncMessage!.contains('success')
                    ? AppColors.securitySuccess
                    : AppColors.onErrorContainer,
              ),
            ),
          ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _QueueCard(item: _items[i]),
          ),
        ),

        // Sync button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: FilledButton.icon(
            onPressed: _syncing ? null : _syncNow,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: _syncing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, color: Colors.white),
            label: Text(
              _syncing ? 'Syncing…' : 'Sync Now',
              style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Queue card ─────────────────────────────────────────────────────────────

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});
  final QueuedCheckin item;

  @override
  Widget build(BuildContext context) {
    final p       = item.payload;
    final isIn    = (p['log_type'] as String? ?? 'IN') == 'IN';
    final lat     = p['gps_lat_smoothed'] as String? ?? '--';
    final lng     = p['gps_lng_smoothed'] as String? ?? '--';
    final band    = p['wifi_band'] as String? ?? 'UNAVAILABLE';
    final ssid    = p['wifi_ssid'] as String? ?? '';
    final tsRaw   = p['timestamp_device'] as String?;
    final dt      = tsRaw != null ? DateTime.parse(tsRaw).toLocal() : null;
    final time    = dt != null ? _fmt(dt, time: true)  : '--';
    final date    = dt != null ? _fmt(dt, time: false) : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.15)),
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
          _InfoRow(Icons.access_time_rounded, time,
              bold: true, color: AppColors.onBackground),
          const SizedBox(height: 6),
          _InfoRow(Icons.location_on_rounded, '$lat, $lng'),
          const SizedBox(height: 6),
          _InfoRow(Icons.wifi_rounded,
              ssid.isNotEmpty ? '$ssid ($band)' : band),
        ],
      ),
    );
  }

  String _fmt(DateTime dt, {required bool time}) {
    if (time) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
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
          Text(label,
              style: AppTextStyles.labelXs
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text,
      {this.bold = false, this.color});
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
