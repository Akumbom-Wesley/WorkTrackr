import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository() : _dio = DioClient.instance.dio;

  final Dio _dio;

  static const String _me = '/auth/me/';
  static const String _history = '/employees/me/history/';
  static String _status(int employeeId) => '/employees/$employeeId/status/';

  Future<MeResponse> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>(_me);
    return MeResponse.fromJson(response.data!);
  }

  Future<TodaySummary> fetchTodaySummary() async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _dio.get<Map<String, dynamic>>(
        _history,
        queryParameters: {'date_from': todayStr, 'date_to': todayStr},
      ),
      _dio.get<Map<String, dynamic>>(
        _history,
        queryParameters: {'date_from': mondayStr, 'date_to': todayStr},
      ),
    ]);

    final todayAttendance = (results[0].data!['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final weekAttendance = (results[1].data!['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return TodaySummary.fromAttendance(todayAttendance, weekAttendance: weekAttendance);
  }

  Future<EmployeeStatusResponse> fetchStatus(int employeeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _status(employeeId),
    );
    return EmployeeStatusResponse.fromJson(response.data!);
  }

  Future<DashboardData> fetchAll() async {
    final me = await fetchMe();

    final results = await Future.wait([
      fetchTodaySummary(),
      if (me.employeeId != null) fetchStatus(me.employeeId!),
    ]);

    final todaySummary = results[0] as TodaySummary;
    final statusResult = me.employeeId != null
        ? results[1] as EmployeeStatusResponse
        : const EmployeeStatusResponse();

    return DashboardData(
      me: me,
      employeeStatus: statusResult,
      todaySummary: todaySummary,
    );
  }
}
