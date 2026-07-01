import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/hr_company_models.dart';

class HrCompanyRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<HrCompanyInfo> fetchCompanyInfo() async {
    final response = await _dio.get('/companies/me/');
    return HrCompanyInfo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HrGeofenceSite> fetchGeofenceSite() async {
    final response = await _dio.get('/companies/geofence-site/');
    return HrGeofenceSite.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HrCompanySettings> fetchAll() async {
    final results = await Future.wait([
      fetchCompanyInfo(),
      fetchGeofenceSite(),
    ]);
    return HrCompanySettings(
      info:     results[0] as HrCompanyInfo,
      geofence: results[1] as HrGeofenceSite,
    );
  }
}
