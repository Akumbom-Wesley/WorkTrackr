import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../model/dashboard_models.dart';

class GreetingCard extends StatefulWidget {
  const GreetingCard({
    super.key,
    required this.me,
    required this.status,
    required this.todaySummary,
    this.onStatusTap,
    this.onClockInTap,
  });

  final MeResponse me;
  final EmployeeStatusResponse status;
  final TodaySummary todaySummary;
  final VoidCallback? onStatusTap;
  final VoidCallback? onClockInTap;

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _isCurrentlyIn =>
      widget.status.status == 'present' ||
      widget.status.status == 'break' ||
      widget.status.status == 'errand' ||
      widget.status.status == 'assignment';

  bool get _hasCheckedInToday => widget.todaySummary.clockIn != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Not yet clocked in banner
          if (!_hasCheckedInToday) _NotClockedInBanner(),
          if (_hasCheckedInToday && !_isCurrentlyIn) _ClockedOutBanner(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopRow(now: _now, clockInTime: widget.todaySummary.clockIn, isCurrentlyIn: _isCurrentlyIn),
                const SizedBox(height: 12),
                _GreetingText(me: widget.me),
                const SizedBox(height: 16),
                _ValidationChips(isCurrentlyIn: _isCurrentlyIn, hasCheckedInToday: _hasCheckedInToday),
                const SizedBox(height: 20),
                _ClockInButton(
                  isCheckedIn: _isCurrentlyIn,
                  onTap: widget.onClockInTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Not clocked in banner ─────────────────────────────────────────────────

class _NotClockedInBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.securityWarning.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.securityWarning.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.securityWarning,
          ),
          const SizedBox(width: 8),
          Text(
            'Not yet clocked in for today',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.securityWarning,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clocked out banner ───────────────────────────────────────────────────

class _ClockedOutBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.securitySuccess.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.securitySuccess.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.securitySuccess,
          ),
          const SizedBox(width: 8),
          Text(
            'Clocked out for today',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.securitySuccess,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top row ───────────────────────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({required this.now, required this.clockInTime, required this.isCurrentlyIn});
  final DateTime? clockInTime;
  final DateTime now;
  final bool isCurrentlyIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCurrentlyIn ? 'CLOCKED IN AT' : (clockInTime != null ? 'CLOCKED OUT' : 'NOT CLOCKED IN'),
          style: AppTextStyles.labelXs.copyWith(
            color: AppColors.onPrimaryContainer,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(now),
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onPrimary,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              clockInTime != null ? _formatClockIn(clockInTime!) : _formatDate(now),
              style: AppTextStyles.labelXs.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatClockIn(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Greeting text ─────────────────────────────────────────────────────────

class _GreetingText extends StatelessWidget {
  const _GreetingText({required this.me});
  final MeResponse me;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
            ? 'Good Afternoon,'
            : 'Good Evening,';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting\n${me.displayFirstName}.',
          style: AppTextStyles.headlineLgMobile.copyWith(
            color: AppColors.onPrimary,
            height: 1.2,
          ),
        ),

      ],
    );
  }
}

// ── Validation chips ──────────────────────────────────────────────────────

class _ValidationChips extends StatelessWidget {
  const _ValidationChips({required this.isCurrentlyIn, required this.hasCheckedInToday});
  final bool isCurrentlyIn;
  final bool hasCheckedInToday;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          icon: Icons.my_location_rounded,
          label: isCurrentlyIn ? 'GPS Validated' : (hasCheckedInToday ? 'GPS Validated' : 'GPS Pending'),
          state: hasCheckedInToday ? _ChipState.success : _ChipState.pending,
        ),
        _Chip(
          icon: Icons.fingerprint,
          label: isCurrentlyIn ? 'Bio Verified' : (hasCheckedInToday ? 'Bio Verified' : 'Bio Pending'),
          state: hasCheckedInToday ? _ChipState.success : _ChipState.pending,
        ),
        _Chip(
          icon: Icons.wifi_rounded,
          label: isCurrentlyIn ? 'Network Secure' : (hasCheckedInToday ? 'Network Secure' : 'Network Pending'),
          state: hasCheckedInToday ? _ChipState.success : _ChipState.pending,
        ),
      ],
    );
  }
}

enum _ChipState { success, pending, error }

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final _ChipState state;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color border;

    switch (state) {
      case _ChipState.success:
        fg = AppColors.securitySuccess;
        bg = AppColors.securitySuccess.withValues(alpha: 0.15);
        border = AppColors.securitySuccess.withValues(alpha: 0.3);
      case _ChipState.pending:
        fg = AppColors.onPrimaryContainer;
        bg = AppColors.onPrimary.withValues(alpha: 0.08);
        border = AppColors.onPrimaryContainer.withValues(alpha: 0.3);
      case _ChipState.error:
        fg = AppColors.securityError;
        bg = AppColors.securityError.withValues(alpha: 0.15);
        border = AppColors.securityError.withValues(alpha: 0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ── Clock-in button ───────────────────────────────────────────────────────

class _ClockInButton extends StatelessWidget {
  const _ClockInButton({required this.isCheckedIn, this.onTap});

  final bool isCheckedIn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = isCheckedIn ? 'CLOCK OUT' : 'CLOCK IN';
    final icon = isCheckedIn ? Icons.logout_rounded : Icons.login_rounded;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onPrimary,
          foregroundColor: AppColors.primaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: AppColors.primaryContainer,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
