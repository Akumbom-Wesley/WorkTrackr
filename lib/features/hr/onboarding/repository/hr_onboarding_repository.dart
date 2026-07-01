import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../employees/model/hr_employee_models.dart';
import '../../employees/repository/hr_employee_repository.dart';

class HrOnboardingRepository {
  HrOnboardingRepository()
      : _dio = DioClient.instance.dio,
        _employeeRepo = HrEmployeeRepository();

  final Dio _dio;
  final HrEmployeeRepository _employeeRepo;

  /// Single pass-through to the shared employee stream. No separate cache
  /// here — HrEmployeeRepository is the single source of truth.
  Stream<List<HrEmployee>> watchAll() => _employeeRepo.watchAll();

  // ── Stub actions ──────────────────────────────────────────────────────
  // Endpoints exist on the backend per user confirmation; wiring these
  // up correctly (request/response shape) is a follow-up task. For now
  // these hit placeholder paths so the UI has something real to call.
  Future<void> sendOnboardingEmail(int employeeId) async {
    await _dio.post('/employees/$employeeId/send-onboarding-email/');
  }

  Future<void> sendAllPendingEmails() async {
    await _dio.post('/employees/send-onboarding-emails/');
  }
}
