import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/history_models.dart';
import '../repository/history_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────

final historyRepositoryProvider = Provider<HistoryRepository>(
  (_) => HistoryRepository(),
);

// ── Date range state ──────────────────────────────────────────────────────

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange({required this.from, required this.to});
}

/// Defaults to current calendar month.
DateTime get _monthStart {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

DateTime get _monthEnd {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1, 0);
}

final historyDateRangeProvider = StateProvider<DateRange>(
  (_) => DateRange(from: _monthStart, to: _monthEnd),
);

// ── Notifier ──────────────────────────────────────────────────────────────

class HistoryNotifier extends AsyncNotifier<HistoryReport> {
  @override
  Future<HistoryReport> build() => _load();

  Future<HistoryReport> _load() async {
    final range = ref.watch(historyDateRangeProvider);
    HistoryReport? latest;
    Object? streamError;
    StackTrace? streamStack;

    await ref
        .read(historyRepositoryProvider)
        .watchHistory(dateFrom: range.from, dateTo: range.to)
        .listen(
          (report) {
            latest = report;
            state = AsyncData(report);
          },
          onError: (error, stackTrace) {
            streamError = error;
            streamStack = stackTrace as StackTrace;
            state = AsyncError(error, stackTrace);
          },
        )
        .asFuture<void>();

    if (latest == null) {
      throw Error.throwWithStackTrace(
        streamError ?? StateError('History stream completed with no data'),
        streamStack ?? StackTrace.current,
      );
    }
    return latest!;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, HistoryReport>(HistoryNotifier.new);

// ── Friendly error helper (reused in screen) ──────────────────────────────

String friendlyHistoryError(Object err) {
  if (err is DioException) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'No internet connection. Showing cached data if available.';
      case DioExceptionType.badResponse:
        if (err.response?.statusCode == 401) {
          return 'Your session has expired. Please log in again.';
        }
        return 'Something went wrong. Please try again.';
      default:
        break;
    }
  }
  return 'Something went wrong. Please try again.';
}
