import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

/// Singleton Dio client with:
/// - One instance shared across the app (no re-creation on every call)
/// - JWT Bearer token injected on every request via interceptor
/// - Silent token refresh on 401 via the refresh endpoint
/// - Request/response logging in debug builds only
class DioClient {
  DioClient._();

  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio = _createDio();

  /// The configured Dio instance — use this everywhere.
  Dio get dio => _dio;

  // ── Factory ──────────────────────────────────────────────────────────────

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Return the raw response on any status so our interceptor
        // can inspect 401s before Dio throws.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      if (kDebugMode) _loggingInterceptor(),
    ]);

    return dio;
  }

  Interceptor _loggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      logPrint: (o) => debugPrint('[DIO] $o'),
    );
  }
}

// ── Auth interceptor ──────────────────────────────────────────────────────

/// Attaches the Bearer token to every request.
/// On 401, attempts a silent token refresh then retries the original request.
/// On refresh failure, clears tokens (user must log in again).
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  final SecureStorage _storage = SecureStorage.instance;

  // Separate Dio for refresh calls — avoids interceptor recursion.
  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(
        milliseconds: AppConstants.connectTimeout,
      ),
      receiveTimeout: const Duration(
        milliseconds: AppConstants.receiveTimeout,
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token =
    await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    // 401 — try silent refresh
    if (response.statusCode == 401) {
      final retried = await _tryRefreshAndRetry(response.requestOptions);
      if (retried != null) {
        handler.resolve(retried);
        return;
      }
      // Refresh failed — clear tokens, propagate the 401
      await _clearTokens();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Response?> _tryRefreshAndRetry(RequestOptions original) async {
    try {
      final refreshToken =
      await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return null;

      final refreshResponse = await _refreshDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (refreshResponse.statusCode == 200) {
        final newAccess =
        refreshResponse.data['access'] as String;

        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: newAccess,
        );

        // Retry original request with new token
        final retryOptions = original.copyWith(
          headers: {
            ...original.headers,
            'Authorization': 'Bearer $newAccess',
          },
        );

        return await _dio.fetch(retryOptions);
      }
    } catch (_) {
      // Refresh call itself failed — fall through to clear tokens
    }
    return null;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.roleKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }
}