import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../employee/history/providers/history_providers.dart' show DateRange;
import '../model/hr_employee_models.dart';
import '../repository/hr_employee_repository.dart';

final hrEmployeeRepositoryProvider = Provider<HrEmployeeRepository>(
  (_) => HrEmployeeRepository(),
);

// ── Employee list ──────────────────────────────────────────────────────────
//
// Cache-then-network: subscribes to watchAll(), updates state on each
// emission (cached list first if present, then fresh list once the
// network call resolves) — same shape as DashboardNotifier/
// HrDashboardNotifier/HistoryNotifier.

class HrEmployeeListNotifier extends AsyncNotifier<List<HrEmployee>> {
  @override
  Future<List<HrEmployee>> build() => _load();

  Future<List<HrEmployee>> _load() async {
    List<HrEmployee>? latest;
    Object? streamError;
    StackTrace? streamStackTrace;

    await ref
        .read(hrEmployeeRepositoryProvider)
        .watchAll()
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

    if (latest == null) {
      throw Error.throwWithStackTrace(
        streamError ?? StateError('Employee list stream completed with no data'),
        streamStackTrace ?? StackTrace.current,
      );
    }
    return latest!;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final hrEmployeeListProvider =
    AsyncNotifierProvider<HrEmployeeListNotifier, List<HrEmployee>>(
  HrEmployeeListNotifier.new,
);

// ── Filter ───────────────────────────────────────────────────────────────

enum HrEmployeeFilter { all, active, inactive, notOnboarded }

final hrEmployeeFilterProvider =
    StateProvider<HrEmployeeFilter>((ref) => HrEmployeeFilter.all);

final hrSearchQueryProvider = StateProvider<String>((ref) => '');

final hrFilteredEmployeeListProvider = Provider<AsyncValue<List<HrEmployee>>>(
  (ref) {
    final listAsync = ref.watch(hrEmployeeListProvider);
    final filter = ref.watch(hrEmployeeFilterProvider);
    final query = ref.watch(hrSearchQueryProvider).trim().toLowerCase();

    return listAsync.whenData((list) {
      var result = switch (filter) {
        HrEmployeeFilter.all => list,
        HrEmployeeFilter.active =>
          list.where((e) => e.isActive).toList(),
        HrEmployeeFilter.inactive =>
          list.where((e) => !e.isActive).toList(),
        HrEmployeeFilter.notOnboarded =>
          list.where((e) => !e.isOnboarded).toList(),
      };

      if (query.isNotEmpty) {
        result = result
            .where((e) =>
                e.fullName.toLowerCase().contains(query) ||
                e.erpnextEmployeeId.toLowerCase().contains(query) ||
                e.department.toLowerCase().contains(query))
            .toList();
      }

      return result;
    });
  },
);

// ── Employee detail (profile + history + audit loaded together) ────────────
//
// Keyed as a family on employeeId alone (NOT on date range — see
// hrEmployeeDateRangeProvider below). This fixes two bugs from the old
// global-singleton + StateProvider-args design:
//   1. build() previously only ran once on construction, so it threw
//      'No employee selected' if args were null at that point.
//   2. Subsequent taps on a different employee updated the shared args
//      provider but the singleton notifier never re-ran, so it kept
//      showing the first-loaded employee's data.
// Keying the family on employeeId alone (rather than employeeId+dateFrom+
// dateTo together) avoids spinning up a brand-new notifier instance (and
// refetching employee+audit needlessly) every time the user only changes
// the attendance date range — changeRange() below does a targeted
// history-only refetch instead.

class HrEmployeeDetailData {
  final HrEmployee employee;
  final HrEmployeeHistory history;
  final HrCheckinAudit? audit;

  const HrEmployeeDetailData({
    required this.employee,
    required this.history,
    this.audit,
  });

  HrEmployeeDetailData copyWith({
    HrEmployee? employee,
    HrEmployeeHistory? history,
    HrCheckinAudit? audit,
  }) {
    return HrEmployeeDetailData(
      employee: employee ?? this.employee,
      history: history ?? this.history,
      audit: audit ?? this.audit,
    );
  }
}

DateTime get _monthStart {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

/// Per-employee date range for the attendance tab. Keyed separately from
/// the detail family provider so changing the range doesn't tear down and
/// re-fetch the employee/audit data along with it. Keying by employeeId
/// (rather than one shared range) means switching back to a previously
/// viewed employee in the same session restores their last-viewed range.
final hrEmployeeDateRangeProvider =
    StateProvider.family<DateRange, int>(
  (ref, employeeId) => DateRange(from: _monthStart, to: DateTime.now()),
);

String _isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HrEmployeeDetailNotifier
    extends FamilyAsyncNotifier<HrEmployeeDetailData, int> {
  @override
  Future<HrEmployeeDetailData> build(int employeeId) => _fetch(employeeId);

  Future<HrEmployeeDetailData> _fetch(int employeeId) async {
    final repo = ref.read(hrEmployeeRepositoryProvider);
    // Read (not watch) — this notifier owns the history refetch explicitly
    // via changeRange(), so build() shouldn't re-run just because the
    // range changed.
    final range = ref.read(hrEmployeeDateRangeProvider(employeeId));
    final results = await Future.wait([
      repo.fetchOne(employeeId),
      repo.fetchHistory(
        employeeId,
        dateFrom: _isoDate(range.from),
        dateTo: _isoDate(range.to),
      ),
      repo.fetchLastAudit(employeeId),
    ]);
    return HrEmployeeDetailData(
      employee: results[0] as HrEmployee,
      history:  results[1] as HrEmployeeHistory,
      audit:    results[2] as HrCheckinAudit?,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  /// Targeted refetch: updates the date range for this employee, re-fetches
  /// only the history sub-resource, and merges it into the existing
  /// AsyncData — leaves employee/audit untouched.
  Future<void> changeRange(String dateFrom, String dateTo) async {
    final from = DateTime.parse(dateFrom);
    final to = DateTime.parse(dateTo);
    ref.read(hrEmployeeDateRangeProvider(arg).notifier).state =
        DateRange(from: from, to: to);

    final current = state.valueOrNull;
    final repo = ref.read(hrEmployeeRepositoryProvider);
    try {
      final newHistory = await repo.fetchHistory(
        arg,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      if (current != null) {
        state = AsyncData(current.copyWith(history: newHistory));
      } else {
        state = await AsyncValue.guard(() => _fetch(arg));
      }
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final hrEmployeeDetailProvider = AsyncNotifierProvider.family<
    HrEmployeeDetailNotifier, HrEmployeeDetailData, int>(
  HrEmployeeDetailNotifier.new,
);
