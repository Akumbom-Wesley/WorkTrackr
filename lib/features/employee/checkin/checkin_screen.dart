import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';

enum _CheckInStep { biometric, wifi, gps, done, failed }

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  _CheckInStep _step = _CheckInStep.biometric;
  String? _failureReason;

  // Pulse animation for the active step icon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Auto-start pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Dummy pipeline ────────────────────────────────────────────────────

  Future<void> _runPipeline() async {
    // Step 1 — Biometric
    await _simulateStep(_CheckInStep.biometric, 2000);
    if (!mounted) return;

    // Step 2 — Wi-Fi
    setState(() => _step = _CheckInStep.wifi);
    await _simulateStep(_CheckInStep.wifi, 1500);
    if (!mounted) return;

    // Step 3 — GPS
    setState(() => _step = _CheckInStep.gps);
    await _simulateStep(_CheckInStep.gps, 2000);
    if (!mounted) return;

    // Done
    setState(() => _step = _CheckInStep.done);
    _pulseController.stop();

    // Auto return to dashboard after 2s
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go(AppRoutes.employeeDashboard);
  }

  Future<void> _simulateStep(_CheckInStep step, int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onPrimary),
          onPressed: () => context.go(AppRoutes.employeeDashboard),
        ),
        title: Text(
          _step == _CheckInStep.done ? 'Clock In Complete' : 'Clock In',
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.onPrimary,
          ),
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
    if (_step == _CheckInStep.done) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.securitySuccess.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.securitySuccess,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 52,
          color: AppColors.securitySuccess,
        ),
      );
    }

    if (_step == _CheckInStep.failed) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.securityError.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.securityError, width: 2),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 52,
          color: AppColors.securityError,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.onTertiaryContainer,
            width: 2,
          ),
        ),
        child: Icon(
          _stepIcon(_step),
          size: 48,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildStepTitle() {
    return Text(
      _stepTitle(_step),
      style: AppTextStyles.headlineLgMobile.copyWith(
        color: AppColors.onPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStepSubtitle() {
    return Text(
      _stepSubtitle(_step),
      style: AppTextStyles.bodyMd.copyWith(
        color: AppColors.inversePrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStepList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _StepRow(
            icon: Icons.fingerprint_rounded,
            label: 'Biometric Verification',
            state: _rowState(_CheckInStep.biometric),
          ),
          const SizedBox(height: 16),
          _StepRow(
            icon: Icons.wifi_rounded,
            label: 'Wi-Fi Credential Check',
            state: _rowState(_CheckInStep.wifi),
          ),
          const SizedBox(height: 16),
          _StepRow(
            icon: Icons.my_location_rounded,
            label: 'GPS Location Check',
            state: _rowState(_CheckInStep.gps),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  _RowState _rowState(_CheckInStep forStep) {
    if (_step == _CheckInStep.done) return _RowState.success;
    if (_step == _CheckInStep.failed && forStep == _step) {
      return _RowState.failed;
    }
    final order = [
      _CheckInStep.biometric,
      _CheckInStep.wifi,
      _CheckInStep.gps,
    ];
    final currentIdx = order.indexOf(_step);
    final stepIdx = order.indexOf(forStep);
    if (stepIdx < currentIdx) return _RowState.success;
    if (stepIdx == currentIdx) return _RowState.loading;
    return _RowState.pending;
  }

  IconData _stepIcon(_CheckInStep step) {
    switch (step) {
      case _CheckInStep.biometric:
        return Icons.fingerprint_rounded;
      case _CheckInStep.wifi:
        return Icons.wifi_rounded;
      case _CheckInStep.gps:
        return Icons.my_location_rounded;
      case _CheckInStep.done:
        return Icons.check_rounded;
      case _CheckInStep.failed:
        return Icons.close_rounded;
    }
  }

  String _stepTitle(_CheckInStep step) {
    switch (step) {
      case _CheckInStep.biometric:
        return 'Verifying Identity';
      case _CheckInStep.wifi:
        return 'Checking Network';
      case _CheckInStep.gps:
        return 'Acquiring Location';
      case _CheckInStep.done:
        return 'Clock In Successful';
      case _CheckInStep.failed:
        return 'Verification Failed';
    }
  }

  String _stepSubtitle(_CheckInStep step) {
    switch (step) {
      case _CheckInStep.biometric:
        return 'Place your finger on the sensor\nor look at your phone';
      case _CheckInStep.wifi:
        return 'Confirming office network\ncredentials';
      case _CheckInStep.gps:
        return 'Confirming you are within\nthe office geofence';
      case _CheckInStep.done:
        return 'Your attendance has been\nrecorded successfully';
      case _CheckInStep.failed:
        return _failureReason ?? 'Please try again';
    }
  }
}

// ── Step row widget ───────────────────────────────────────────────────────

enum _RowState { pending, loading, success, failed }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.state,
  });

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
        trailing = const Icon(
          Icons.radio_button_unchecked,
          size: 20,
          color: AppColors.onPrimaryContainer,
        );
      case _RowState.loading:
        color = AppColors.onPrimary;
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.secondaryFixed,
          ),
        );
      case _RowState.success:
        color = AppColors.securitySuccess;
        trailing = const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.securitySuccess,
        );
      case _RowState.failed:
        color = AppColors.securityError;
        trailing = const Icon(
          Icons.cancel_rounded,
          size: 20,
          color: AppColors.securityError,
        );
    }

    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: color),
          ),
        ),
        trailing,
      ],
    );
  }
}
