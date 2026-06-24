import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Large prominent check-in / check-out button.
/// Spec §2.4: "Large prominent FAB-style button."
/// Label flips between 'Check In' and 'Check Out' based on [isCheckedIn].
class CheckInFab extends StatelessWidget {
  const CheckInFab({
    super.key,
    required this.isCheckedIn,
    required this.onTap,
  });

  final bool isCheckedIn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isCheckedIn ? 'Check Out' : 'Check In';
    final bgColor =
    isCheckedIn ? cs.onSurfaceVariant : cs.secondary;
    final icon =
    isCheckedIn ? Icons.logout_rounded : Icons.login_rounded;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}