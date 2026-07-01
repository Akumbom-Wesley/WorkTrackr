import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/hr_dashboard_models.dart';
import '../repository/hr_dashboard_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────

final hrDashboardRepositoryProvider = Provider<HrDashboardRepository>(
  (_) => HrDashboardRepository(),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class HrDashboardNotifier extends AsyncNotifier<HrDashboardStats> {
  @override
  Future<HrDashboardStats> build() => _load();

  /// Subscribes to the cache-then-network stream. Each emission updates
  /// state immediately (cached stats first, then fresh stats once the
  /// network call resolves). Returns once the stream completes.
  Future<HrDashboardStats> _load() async {
    HrDashboardStats? latest;
    Object? streamError;
    StackTrace? streamStackTrace;

    await ref
        .read(hrDashboardRepositoryProvider)
        .watchHrStats()
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
        streamError ?? StateError('HR dashboard stream completed with no data'),
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

final hrDashboardProvider =
    AsyncNotifierProvider<HrDashboardNotifier, HrDashboardStats>(
  HrDashboardNotifier.new,
);
