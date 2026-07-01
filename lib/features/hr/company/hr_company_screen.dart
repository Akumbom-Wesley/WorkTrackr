import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'model/hr_company_models.dart';
import 'providers/hr_company_providers.dart';

class HrCompanyScreen extends ConsumerWidget {
  const HrCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(hrCompanyProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimary,
        title: Text(
          'Company Settings',
          style: AppTextStyles.headlineMd.copyWith(color: cs.onPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(hrCompanyProvider.notifier).refresh(),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const _CompanyShimmer(),
        error: (_, __) => _CompanyError(
          onRetry: () => ref.read(hrCompanyProvider.notifier).refresh(),
        ),
        data: (settings) => _CompanyBody(settings: settings),
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _CompanyBody extends StatelessWidget {
  const _CompanyBody({required this.settings});
  final HrCompanySettings settings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Company identity card
        _SectionCard(
          title: 'Company Identity',
          icon: Icons.business_outlined,
          iconColor: AppColors.secondary,
          rows: [
            _Row(label: 'Name',          value: settings.info.name),
            _Row(label: 'ERPNext ID',    value: settings.info.erpnextDocName),
            _Row(
              label: 'Status',
              value: settings.info.isActive ? 'Active' : 'Inactive',
              valueColor: settings.info.isActive
                  ? AppColors.securitySuccess
                  : AppColors.securityError,
            ),
            _Row(
              label: 'Created',
              value: _fmtDate(settings.info.createdAt),
            ),
            _Row(
              label: 'Last Updated',
              value: _fmtDate(settings.info.updatedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Geofence / Wi-Fi card
        _SectionCard(
          title: 'Attendance Site',
          icon: Icons.location_on_outlined,
          iconColor: AppColors.secondary,
          rows: [
            _Row(label: 'Wi-Fi SSID',    value: settings.geofence.wifiSsid),
            _Row(label: 'Wi-Fi BSSID',   value: settings.geofence.wifiBssid),
            _Row(
              label: 'RSSI Threshold',
              value: '${settings.geofence.rssiThreshold} dBm',
            ),
            _Row(
              label: 'Enforce 5 GHz',
              value: settings.geofence.enforce5ghz ? 'Yes' : 'No',
              valueColor: settings.geofence.enforce5ghz
                  ? AppColors.securitySuccess
                  : AppColors.securityWarning,
            ),
            _Row(
              label: 'Latitude',
              value: settings.geofence.latitude.toStringAsFixed(6),
            ),
            _Row(
              label: 'Longitude',
              value: settings.geofence.longitude.toStringAsFixed(6),
            ),
            _Row(
              label: 'Geofence Radius',
              value: '${settings.geofence.radiusMetres} m',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Map preview tile
        _MapPreviewTile(
          latitude: settings.geofence.latitude,
          longitude: settings.geofence.longitude,
          radiusMetres: settings.geofence.radiusMetres,
        ),
      ],
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ── Section card ───────────────────────────────────────────────────────────

class _Row {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.map((r) => _RowWidget(row: r)),
        ],
      ),
    );
  }
}

class _RowWidget extends StatelessWidget {
  const _RowWidget({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: AppTextStyles.bodyMd
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              style: AppTextStyles.bodyMd.copyWith(
                color: row.valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map preview tile ───────────────────────────────────────────────────────

class _MapPreviewTile extends StatelessWidget {
  const _MapPreviewTile({
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
  });

  final double latitude;
  final double longitude;
  final int radiusMetres;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Static map preview via OpenStreetMap tile — no API key needed
    final zoom = 16;
    final tileUrl =
        'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=600x200'
        '&markers=$latitude,$longitude,red-pushpin';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.map_outlined,
                    size: 16, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  'GEOFENCE LOCATION',
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Image.network(
              tileUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined,
                          size: 36, color: cs.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        '$latitude, $longitude',
                        style: AppTextStyles.labelSm
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        'Radius: ${radiusMetres}m',
                        style: AppTextStyles.labelXs
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
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

// ── Shimmer ────────────────────────────────────────────────────────────────

class _CompanyShimmer extends StatelessWidget {
  const _CompanyShimmer();

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).dividerColor.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
              height: 220,
              decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(
              height: 220,
              decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(
              height: 180,
              decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────

class _CompanyError extends StatelessWidget {
  const _CompanyError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Could not load company settings.',
            style: AppTextStyles.bodyMd
                .copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.secondary,
              side: BorderSide(color: cs.secondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
