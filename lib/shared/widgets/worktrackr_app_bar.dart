import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return AppBar(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 4,
      leading: IconButton(
        icon: Icon(
          Icons.grid_view_rounded,
          color: cs.onSurfaceVariant,
          size: 24,
        ),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/worktrackr.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'WorkTrackr',
            style: AppTextStyles.headlineMd.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      actions: actions ??
          [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: cs.onSurfaceVariant,
              ),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 4),
          ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: cs.outlineVariant),
      ),
    );
  }
}
