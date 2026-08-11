import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../features/offline/sync/sync_service.dart';

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
          const SizedBox(width: 12),
          // Sync status indicator
          ValueListenableBuilder<SyncStatus>(
            valueListenable: SyncService.instance.status,
            builder: (context, status, child) {
              if (status == SyncStatus.idle) return const SizedBox.shrink();
              
              return _SyncIndicator(status: status);
            },
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

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    bool rotate = false;

    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = cs.primary;
        rotate = true;
        break;
      case SyncStatus.success:
        icon = Icons.cloud_done_rounded;
        color = Colors.green;
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off_rounded;
        color = cs.error;
        break;
      case SyncStatus.idle:
        return const SizedBox.shrink();
    }

    Widget iconWidget = Icon(icon, size: 16, color: color);

    if (rotate) {
      iconWidget = _RotatingWidget(child: iconWidget);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          if (status == SyncStatus.syncing) ...[
            const SizedBox(width: 6),
            Text(
              'Syncing...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _RotatingWidget extends StatefulWidget {
  const _RotatingWidget({required this.child});
  final Widget child;

  @override
  State<_RotatingWidget> createState() => _RotatingWidgetState();
}

class _RotatingWidgetState extends State<_RotatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}
