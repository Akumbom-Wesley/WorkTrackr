import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class GeofenceCard extends StatefulWidget {
  const GeofenceCard({super.key});

  @override
  State<GeofenceCard> createState() => _GeofenceCardState();
}

class _GeofenceCardState extends State<GeofenceCard> {
  final MapController _mapController = MapController();

  Position? _position;
  Placemark? _placemark;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _placemark = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'Location services are disabled.'; _loading = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _error = 'Location permission denied.'; _loading = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission permanently denied.'; _loading = false; });
        return;
      }

      // Wait for a fix with accuracy better than 10m (max 10 readings)
      Position? best;
      int attempts = 0;
      await for (final pos in Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      )) {
        attempts++;
        if (best == null || pos.accuracy < best.accuracy) best = pos;
        if (best.accuracy <= 10.0 || attempts >= 10) break;
      }
      final position = best!;

      if (!mounted) return;
      setState(() { _position = position; _loading = false; });

      _mapController.move(LatLng(position.latitude, position.longitude), 16);

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        if (mounted && placemarks.isNotEmpty) {
          setState(() => _placemark = placemarks.first);
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not get location.'; _loading = false; });
    }
  }

  String _fmt(double v) => v.toStringAsFixed(5);

  String get _address {
    if (_placemark == null) return '';
    return [_placemark!.street, _placemark!.locality, _placemark!.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOUR LOCATION', style: AppTextStyles.labelXs.copyWith(color: AppColors.outline)),
                GestureDetector(
                  onTap: _fetchLocation,
                  child: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: SizedBox(
              height: 180,
              child: _position == null
                  ? Container(
                      color: AppColors.surfaceContainerLow,
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2)
                            : const Icon(Icons.location_off_rounded, color: AppColors.onSurfaceVariant, size: 32),
                      ),
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(_position!.latitude, _position!.longitude),
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.worktrackr.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_position!.latitude, _position!.longitude),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _error != null
                ? Row(children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.securityWarning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_error!, style: AppTextStyles.labelSm.copyWith(color: AppColors.securityWarning))),
                    GestureDetector(
                      onTap: _fetchLocation,
                      child: Text('Retry', style: AppTextStyles.labelSm.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ),
                  ])
                : _loading
                    ? Text('Acquiring location…', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_address.isNotEmpty) ...[
                            Text(_address, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onBackground)),
                            const SizedBox(height: 6),
                          ],
                          Row(children: [
                            _CoordChip(label: 'LAT', value: _fmt(_position!.latitude)),
                            const SizedBox(width: 8),
                            _CoordChip(label: 'LNG', value: _fmt(_position!.longitude)),
                          ]),
                          const SizedBox(height: 6),
                          Text('Accuracy: ±${_position!.accuracy.toStringAsFixed(1)}m',
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _CoordChip extends StatelessWidget {
  const _CoordChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ', style: AppTextStyles.labelXs.copyWith(color: AppColors.outline)),
          Text(value, style: AppTextStyles.labelSm.copyWith(color: AppColors.onBackground, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
