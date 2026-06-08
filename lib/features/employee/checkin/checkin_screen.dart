import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'checkin_repository.dart';
import 'checkin_service.dart';

enum _Step { biometric, wifi, gps, done, failed }

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.biometric;
  String? _failureReason;
  String _logType = 'IN';
  bool _resolving = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _service = CheckinService();
  final _repository = CheckinRepository();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runPipeline() async {
    // ── Device check ──────────────────────────────────────────────────
    try {
      final registered = await _repository.isDeviceRegistered();
      if (!registered) {
        await _repository.registerDevice();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _fail('Your device has been deactivated. Contact HR.');
      } else {
        _fail('Device registration failed. Check your connection.');
      }
      return;
    }

    // ── Resolve log type (IN vs OUT) ──────────────────────────────────
    _logType = await _repository.resolveLogType();
    if (!mounted) return;
    setState(() => _resolving = false);

    // ── Step 1: Biometric ─────────────────────────────────────────────
    final bioResult = await _service.runBiometric();
    if (!mounted) return;
    if (!bioResult.passed) {
      _fail(bioResult.errorMessage!);
      return;
    }

    // ── Step 2: Wi-Fi ─────────────────────────────────────────────────
    setState(() => _step = _Step.wifi);
    final WifiResult wifi = await _service.runWifi();
    if (!mounted) return;
    if (!wifi.result.passed) {
      _fail(wifi.result.errorMessage!);
      return;
    }

    // ── Step 3: GPS ───────────────────────────────────────────────────
    setState(() => _step = _Step.gps);
    final GpsResult gps = await _service.runGps();
    if (!mounted) return;
    if (!gps.result.passed || gps.position == null) {
      _fail(gps.result.errorMessage!);
      return;
    }

    // ── Anti-spoofing ─────────────────────────────────────────────────
    final SpoofResult flags = await _service.getAntispoofingFlags(gps.position!);
    if (!mounted) return;

    // ── Submit ────────────────────────────────────────────────────────
    try {
      final deviceId = await _repository.getDeviceUniqueId();

      final payload = CheckinPayload(
        deviceUniqueId: deviceId,
        logType: _logType,
        biometricPassed: true,
        latSmoothed: gps.position!.latitude,
        lngSmoothed: gps.position!.longitude,
        accuracyMetres: gps.position!.accuracy.round(),
        timestampGps: gps.position!.timestamp,
        timestampDevice: DateTime.now().toUtc(),
        wifiBand: wifi.band,
        wifiSsid: wifi.ssid,
        wifiBssid: wifi.bssid,
        rssiAvg: wifi.rssi,
        mockLocation: flags.mockLocation,
        isRooted: flags.isRooted,
      );

      await _repository.submitCheckin(payload.toJson());
      if (!mounted) return;

      setState(() => _step = _Step.done);
      _pulseController.stop();

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.pop();
    } on DioException catch (e) {
      _fail(_mapApiError(e));
    }
  }

  void _fail(String reason) {
    if (!mounted) return;
    setState(() {
      _step = _Step.failed;
      _failureReason = reason;
    });
    _pulseController.stop();
  }

  String _mapApiError(DioException e) {
    final status = e.response?.statusCode;
    final detail = (e.response?.data?['detail'] as String?) ?? '';
    switch (status) {
      case 403:
        if (detail.contains('Mock')) return 'Mock location detected. Disable location spoofing apps.';
        if (detail.contains('Rooted')) return 'Rooted device detected. Cannot use app on rooted devices.';
        if (detail.contains('not registered')) return 'Device not registered. Contact HR.';
        return detail.isNotEmpty ? detail : 'Access denied.';
      case 409:
        return 'You have already clocked ${_logType == 'OUT' ? 'out' : 'in'} today.';
      case 422:
        if (detail.contains('geofence') || detail.contains('Outside')) return 'You are outside the office location.';
        if (detail.contains('Wi-Fi') || detail.contains('RSSI')) return 'Office Wi-Fi not detected or signal too weak.';
        if (detail.contains('Biometric')) return 'Biometric check failed.';
        if (detail.contains('Timestamp') || detail.contains('implausible')) return 'Device clock is out of sync. Check your time settings.';
        if (detail.contains('log type') || detail.contains('INVALID_LOG_TYPE')) return 'Cannot clock out without a prior clock in.';
        return detail.isNotEmpty ? detail : 'Verification failed.';
      case null:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = _resolving
        ? ''
        : (_step == _Step.done
            ? (_logType == 'OUT' ? 'Clock Out Complete' : 'Clock In Complete')
            : (_logType == 'OUT' ? 'Clock Out' : 'Clock In'));

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildStepIcon(),
              const SizedBox(height: 32),
              _buildStepTitle(),
              const SizedBox(height: 12),
              _buildStepSubtitle(),
              const Spacer(),
              _buildStepList(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    if (_step == _Step.done) {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppColors.securitySuccess.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.securitySuccess, width: 2),
        ),
        child: const Icon(Icons.check_rounded, size: 52, color: AppColors.securitySuccess),
      );
    }
    if (_step == _Step.failed) {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppColors.securityError.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.securityError, width: 2),
        ),
        child: const Icon(Icons.close_rounded, size: 52, color: AppColors.securityError),
      );
    }
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnimation.value, child: child),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onTertiaryContainer, width: 2),
        ),
        child: Icon(_stepIcon(_step), size: 48, color: AppColors.onPrimary),
      ),
    );
  }

  Widget _buildStepTitle() => Text(
        _stepTitle(_step),
        style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.onPrimary),
        textAlign: TextAlign.center,
      );

  Widget _buildStepSubtitle() => Text(
        _stepSubtitle(_step),
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.inversePrimary),
        textAlign: TextAlign.center,
      );

  Widget _buildStepList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _StepRow(icon: Icons.fingerprint_rounded, label: 'Biometric Verification', state: _rowState(_Step.biometric)),
          const SizedBox(height: 16),
          _StepRow(icon: Icons.wifi_rounded, label: 'Wi-Fi Credential Check', state: _rowState(_Step.wifi)),
          const SizedBox(height: 16),
          _StepRow(icon: Icons.my_location_rounded, label: 'GPS Location Check', state: _rowState(_Step.gps)),
        ],
      ),
    );
  }

  _RowState _rowState(_Step forStep) {
    final order = [_Step.biometric, _Step.wifi, _Step.gps];
    if (_step == _Step.done) return _RowState.success;
    if (_step == _Step.failed) {
      final currentIdx = order.indexOf(_step);
      final stepIdx = order.indexOf(forStep);
      if (stepIdx < currentIdx) return _RowState.success;
      if (stepIdx == currentIdx) return _RowState.failed;
      return _RowState.pending;
    }
    final currentIdx = order.indexOf(_step);
    final stepIdx = order.indexOf(forStep);
    if (stepIdx < currentIdx) return _RowState.success;
    if (stepIdx == currentIdx) return _RowState.loading;
    return _RowState.pending;
  }

  IconData _stepIcon(_Step step) {
    switch (step) {
      case _Step.biometric: return Icons.fingerprint_rounded;
      case _Step.wifi:      return Icons.wifi_rounded;
      case _Step.gps:       return Icons.my_location_rounded;
      case _Step.done:      return Icons.check_rounded;
      case _Step.failed:    return Icons.close_rounded;
    }
  }

  String _stepTitle(_Step step) {
    switch (step) {
      case _Step.biometric: return 'Verifying Identity';
      case _Step.wifi:      return 'Checking Network';
      case _Step.gps:       return 'Acquiring Location';
      case _Step.done:      return _logType == 'OUT' ? 'Clocked Out Successfully' : 'Clocked In Successfully';
      case _Step.failed:    return 'Verification Failed';
    }
  }

  String _stepSubtitle(_Step step) {
    switch (step) {
      case _Step.biometric: return 'Place your finger on the sensor\nor look at your phone';
      case _Step.wifi:      return 'Confirming office network\ncredentials';
      case _Step.gps:       return 'Confirming you are within\nthe office location';
      case _Step.done:      return 'Your attendance has been\nrecorded successfully';
      case _Step.failed:    return _failureReason ?? 'Please try again';
    }
  }
}

// ── Step row ───────────────────────────────────────────────────────────────

enum _RowState { pending, loading, success, failed }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.label, required this.state});

  final IconData icon;
  final String label;
  final _RowState state;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget trailing;

    switch (state) {
      case _RowState.pending:
        color = AppColors.onPrimaryContainer;
        trailing = const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.onPrimaryContainer);
      case _RowState.loading:
        color = AppColors.onPrimary;
        trailing = const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryFixed),
        );
      case _RowState.success:
        color = AppColors.securitySuccess;
        trailing = const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.securitySuccess);
      case _RowState.failed:
        color = AppColors.securityError;
        trailing = const Icon(Icons.cancel_rounded, size: 20, color: AppColors.securityError);
    }

    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd.copyWith(color: color))),
        trailing,
      ],
    );
  }
}
