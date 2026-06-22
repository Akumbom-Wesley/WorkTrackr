import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Shared drawer for Employee role.
/// Pass [fullName] and [employeeId] from the logged-in user.
class WorkTrackrDrawer extends StatelessWidget {
  const WorkTrackrDrawer({
    super.key,
    this.fullName,
    this.employeeId,
    this.onProfileTap,
    this.onDeviceTap,
    this.onOfflineQueueTap,
    this.onSecurityTap,
    this.onLogoutTap,
  });

  final String? fullName;
  final String? employeeId;
  final VoidCallback? onProfileTap;
  final VoidCallback? onDeviceTap;
  final VoidCallback? onOfflineQueueTap;
  final VoidCallback? onSecurityTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName ?? 'Employee',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    employeeId ?? '',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                onProfileTap?.call();
              },
            ),
            _DrawerItem(
              icon: Icons.devices_rounded,
              label: 'My Device',
              onTap: () {
                Navigator.pop(context);
                onDeviceTap?.call();
              },
            ),
            _DrawerItem(
              icon: Icons.cloud_sync_outlined,
              label: 'Offline Queue',
              onTap: () {
                Navigator.pop(context);
                onOfflineQueueTap?.call();
              },
            ),
            _DrawerItem(
              icon: Icons.shield_outlined,
              label: 'Security Settings',
              onTap: () {
                Navigator.pop(context);
                onSecurityTap?.call();
              },
            ),

            const Spacer(),
            const Divider(color: AppColors.surfaceMuted),

            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onLogoutTap?.call();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.onBackground;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMd.copyWith(
          color: c,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
