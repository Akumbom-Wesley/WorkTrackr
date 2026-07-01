import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/hr_flagged_models.dart';
import '../repository/hr_flagged_repository.dart';

final hrFlaggedRepositoryProvider = Provider<HrFlaggedRepository>(
  (_) => HrFlaggedRepository(),
);

final hrShowResolvedProvider = StateProvider<bool>((ref) => false);

class HrFlaggedNotifier extends AsyncNotifier<List<FlaggedRecord>> {
  @override
  Future<List<FlaggedRecord>> build() => _load();

  /// Subscribes to the cache-then-network stream. Cached list surfaces
  /// immediately (offline-first), then updates once the network call
  /// resolves. Same pattern as HrDashboardNotifier.
  Future<List<FlaggedRecord>> _load() async {
    final showResolved = ref.read(hrShowResolvedProvider);
    List<FlaggedRecord>? latest;
    Object? streamError;
    StackTrace? streamStackTrace;

    try {
      await ref
          .read(hrFlaggedRepositoryProvider)
          .watchFlagged(showResolved: showResolved)
          .listen(
            (data) {
              latest = data;
              state = AsyncData(data);
            },
            onError: (error, stackTrace) {
              streamError = error;
              streamStackTrace = stackTrace as StackTrace;
            },
          )
          .asFuture<void>();
    } catch (e, st) {
      streamError ??= e;
      streamStackTrace ??= st;
    }

    if (latest != null) return latest!;

    throw Error.throwWithStackTrace(
      streamError ??
          StateError('Flagged records stream completed with no data'),
      streamStackTrace ?? StackTrace.current,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> resolve(int id) async {
    final repo = ref.read(hrFlaggedRepositoryProvider);
    final updated = await repo.resolve(id);
    state = state.whenData((list) => [
          for (final r in list)
            if (r.id == id) updated else r,
        ]);
  }
}

final hrFlaggedProvider =
    AsyncNotifierProvider<HrFlaggedNotifier, List<FlaggedRecord>>(
  HrFlaggedNotifier.new,
);
