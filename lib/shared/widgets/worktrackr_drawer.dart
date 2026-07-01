import 'package:flutter/material.dart';
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
    this.isHrAdmin = false,
    this.onEmployeesTap,
    this.onFlaggedTap,
    this.onOnboardingTap,
    this.onCompanyTap,
  });

  final String? fullName;
  final String? employeeId;
  final VoidCallback? onProfileTap;
  final VoidCallback? onDeviceTap;
  final VoidCallback? onOfflineQueueTap;
  final VoidCallback? onSecurityTap;
  final VoidCallback? onLogoutTap;
  final bool isHrAdmin;
  final VoidCallback? onEmployeesTap;
  final VoidCallback? onFlaggedTap;
  final VoidCallback? onOnboardingTap;
  final VoidCallback? onCompanyTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: cs.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName ?? 'Employee',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    employeeId ?? '',
                    style: AppTextStyles.labelSm.copyWith(
                      color: cs.onPrimaryContainer,
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

            if (isHrAdmin) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'HR ADMIN',
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.onPrimaryContainer,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _DrawerItem(
                icon: Icons.people_outline_rounded,
                label: 'People & Employees',
                onTap: () {
                  Navigator.pop(context);
                  onEmployeesTap?.call();
                },
              ),
              _DrawerItem(
                icon: Icons.flag_outlined,
                label: 'Flagged Records',
                onTap: () {
                  Navigator.pop(context);
                  onFlaggedTap?.call();
                },
              ),
              _DrawerItem(
                icon: Icons.mark_email_unread_outlined,
                label: 'Onboarding',
                onTap: () {
                  Navigator.pop(context);
                  onOnboardingTap?.call();
                },
              ),
              _DrawerItem(
                icon: Icons.business_outlined,
                label: 'Company Info',
                onTap: () {
                  Navigator.pop(context);
                  onCompanyTap?.call();
                },
              ),
              const SizedBox(height: 4),
            ],
            const Spacer(),
            Divider(color: cs.outlineVariant),

            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: cs.error,
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
    final c = color ?? Theme.of(context).colorScheme.onSurface;
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
