import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class WorkTrackrAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkTrackrAppBar({
    super.key,
    required this.scaffoldKey,
    this.actions,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 4,
      leading: IconButton(
        icon: const Icon(
          Icons.grid_view_rounded,
          color: AppColors.onSurfaceVariant,
          size: 24,
        ),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.security,
              size: 16,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'WorkTrackr',
            style: AppTextStyles.headlineMd.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
      actions: actions ??
          [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 4),
          ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.surfaceMuted),
      ),
    );
  }
}
