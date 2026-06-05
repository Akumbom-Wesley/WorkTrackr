import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/dashboard_models.dart';
import '../repository/dashboard_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>(
      (_) => DashboardRepository(),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() => _load();

  Future<DashboardData> _load() =>
      ref.read(dashboardRepositoryProvider).fetchAll();

  /// Pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final dashboardProvider =
AsyncNotifierProvider<DashboardNotifier, DashboardData>(
  DashboardNotifier.new,
);