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

  Future<List<AttendanceRecord>> fetchTodayHistory() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final response = await _dio.get<dynamic>(
      _history,
      queryParameters: {'date_from': dateStr, 'date_to': dateStr},
    );

    final data = response.data;
    final List<dynamic> raw = data is List
        ? data
        : (data as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];

    return raw
        .cast<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();
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
      fetchTodayHistory(),
      if (me.employeeId != null) fetchStatus(me.employeeId!),
    ]);

    final records = results[0] as List<AttendanceRecord>;
    final statusResult = me.employeeId != null
        ? results[1] as EmployeeStatusResponse
        : const EmployeeStatusResponse();

    return DashboardData(
      me: me,
      employeeStatus: statusResult,
      todaySummary: TodaySummary.fromRecords(records),
    );
  }
}