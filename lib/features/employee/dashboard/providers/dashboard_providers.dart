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

  /// Subscribes to the cache-then-network stream. Each emission updates
  /// state immediately (cached data first, then fresh data once the
  /// network call resolves). Returns once the stream completes.
  Future<DashboardData> _load() async {
    DashboardData? latest;
    Object? streamError;
    StackTrace? streamStackTrace;

    await ref
        .read(dashboardRepositoryProvider)
        .watchDashboard()
        .listen(
          (data) {
            latest = data;
            state = AsyncData(data);
          },
          onError: (error, stackTrace) {
            streamError = error;
            streamStackTrace = stackTrace as StackTrace;
            state = AsyncError(error, stackTrace);
          },
        )
        .asFuture<void>();

    // Nothing was ever cached and the network call failed too — rethrow
    // the original error so the UI's error message reflects the real
    // cause (e.g. no connection) rather than a generic failure.
    if (latest == null) {
      throw Error.throwWithStackTrace(
        streamError ?? StateError('Dashboard stream completed with no data'),
        streamStackTrace ?? StackTrace.current,
      );
    }
    return latest!;
  }

  /// Pull-to-refresh / retry button.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final dashboardProvider =
AsyncNotifierProvider<DashboardNotifier, DashboardData>(
  DashboardNotifier.new,
);
