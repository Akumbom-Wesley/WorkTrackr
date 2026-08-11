import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../core/constants/app_colors.dart';
import 'worktrackr_app_bar.dart';

/// Reusable nav shell used by both EmployeeDashboardScreen and
/// HrDashboardScreen. Owns the Scaffold, AppBar, Drawer, and
/// PersistentTabView so neither role-specific screen duplicates that logic.
class WorkTrackrNavShell extends StatefulWidget {
  const WorkTrackrNavShell({
    super.key,
    required this.tabs,
    required this.drawer,
  });

  final List<PersistentTabConfig> tabs;
  final Widget drawer;

  @override
  State<WorkTrackrNavShell> createState() => _WorkTrackrNavShellState();
}

class _WorkTrackrNavShellState extends State<WorkTrackrNavShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PersistentTabController _navController;

  @override
  void initState() {
    super.initState();
    _navController = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: WorkTrackrAppBar(scaffoldKey: _scaffoldKey),
      drawer: widget.drawer,
      body: PersistentTabView(
        controller: _navController,
        tabs: widget.tabs,
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: NavBarDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}
