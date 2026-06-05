import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Geofence Target card matching the reference design.
/// Shows a grid map placeholder, pulsing location pin, site name + accuracy.
/// Real GPS data will be injected by the Check-In screen in a later sprint.
class GeofenceCard extends StatefulWidget {
  const GeofenceCard({
    super.key,
    this.siteName = 'Site Alpha — Sector 4',
    this.accuracy = '±4.2m',
  });

  final String siteName;
  final String accuracy;

  @override
  State<GeofenceCard> createState() => _GeofenceCardState();
}

class _GeofenceCardState extends State<GeofenceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GEOFENCE TARGET',
                  style: AppTextStyles.labelXs.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Map placeholder with grid + pulsing pin
          SizedBox(
            height: 160,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.zero,
                bottom: Radius.zero,
              ),
              child: Stack(
                children: [
                  // Grid background
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  // Pulsing pin
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final scale = 1.0 +
                            (_pulse.value * 0.4)
                                .clamp(0.0, 0.4);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse ring
                            Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryContainer
                                        .withValues(
                                      alpha: (1.0 - _pulse.value)
                                          .clamp(0.0, 1.0),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Pin container
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surfaceContainerHigh,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 24,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer: site name + accuracy
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.siteName,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Accuracy: ${widget.accuracy}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..strokeWidth = 1.0;

    const spacing = 24.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}