import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../employees/model/hr_employee_models.dart';
import '../model/hr_onboarding_models.dart';
import '../repository/hr_onboarding_repository.dart';

final hrOnboardingRepositoryProvider = Provider<HrOnboardingRepository>(
  (_) => HrOnboardingRepository(),
);

// ── Combined onboarding data ────────────────────────────────────────────
//
// Single notifier, single subscription to the underlying employee stream
// (via HrOnboardingRepository.watchAll()), deriving both the pending-entries
// list and the stats from each emission. Avoids the previous two-notifier
// design's duplicate /employees/ network call per screen load.

class HrOnboardingData {
  final List<OnboardingEntry> entries;
  final OnboardingStats stats;

  const HrOnboardingData({required this.entries, required this.stats});
}

class HrOnboardingNotifier extends AsyncNotifier<HrOnboardingData> {
  @override
  Future<HrOnboardingData> build() => _load();

  Future<HrOnboardingData> _load() async {
    HrOnboardingData? latest;
    Object? streamError;
    StackTrace? streamStackTrace;

    await ref
        .read(hrOnboardingRepositoryProvider)
        .watchAll()
        .listen(
          (employees) {
            final data = HrOnboardingData(
              entries: _toPendingEntries(employees),
              stats: OnboardingStats.fromEmployees(employees),
            );
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

    if (latest == null) {
      throw Error.throwWithStackTrace(
        streamError ?? StateError('Onboarding stream completed with no data'),
        streamStackTrace ?? StackTrace.current,
      );
    }
    return latest!;
  }

  List<OnboardingEntry> _toPendingEntries(List<HrEmployee> employees) {
    return employees
        .where((e) => !e.isOnboarded)
        .map((e) => OnboardingEntry(
              employee: e,
              emailStatus: OnboardingEmailStatus.notSent,
            ))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final hrOnboardingProvider =
    AsyncNotifierProvider<HrOnboardingNotifier, HrOnboardingData>(
  HrOnboardingNotifier.new,
);

// ── Search (client-side) ────────────────────────────────────────────────

final hrOnboardingSearchQueryProvider = StateProvider<String>((ref) => '');

final hrFilteredOnboardingEntriesProvider =
    Provider<AsyncValue<List<OnboardingEntry>>>((ref) {
  final dataAsync = ref.watch(hrOnboardingProvider);
  final query = ref.watch(hrOnboardingSearchQueryProvider).trim().toLowerCase();

  return dataAsync.whenData((data) {
    if (query.isEmpty) return data.entries;
    return data.entries
        .where((e) =>
            e.employee.fullName.toLowerCase().contains(query) ||
            e.employee.erpnextEmployeeId.toLowerCase().contains(query))
        .toList();
  });
});

// ── Stats convenience accessor (for widgets that only need stats) ────────

final hrOnboardingStatsProvider = Provider<AsyncValue<OnboardingStats>>((ref) {
  return ref.watch(hrOnboardingProvider).whenData((data) => data.stats);
});
