import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

class ApiConfig {
  const ApiConfig._();

  static const baseUrl = 'https://dummyjson.com';
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
  static const sendTimeout = Duration(seconds: 15);
  static const tokenLifetimeMins = 30;
}

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      responseType: ResponseType.json,
      headers: const {'Content-Type': 'application/json'},
    );

/// Builds the single configured [Dio] client used by every data source.
Dio createDio({
  required TokenStorage tokens,
  required void Function() onSessionExpired,
  bool enableLogs = kDebugMode,
}) {
  final dio = Dio(_baseOptions());
  // A separate client without interceptors performs refreshes, so a refresh
  // call can never trigger another refresh.
  final refreshDio = Dio(_baseOptions());

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      refreshDio: refreshDio,
      tokens: tokens,
      onSessionExpired: onSessionExpired,
    ),
  );
  if (enableLogs) dio.interceptors.add(SafeLogInterceptor());
  return dio;
}

/// Attaches the bearer token and transparently refreshes it once on a 401.
/// Concurrent 401s share a single in-flight refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.tokens,
    required this.onSessionExpired,
  });

  final Dio dio;
  final Dio refreshDio;
  final TokenStorage tokens;
  final void Function() onSessionExpired;

  static const _retriedKey = 'auth_retried';
  Future<String?>? _refreshing;

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') || path.contains('/auth/refresh');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_isAuthEndpoint(options.path)) {
        final token = await tokens.readAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || _isAuthEndpoint(request.path)) {
      handler.next(err);
      return;
    }
    try {
      if (request.extra[_retriedKey] == true) {
        await _expire();
        handler.next(err);
        return;
      }
      final stored = await tokens.readAccessToken();
      final sent = request.headers['Authorization'];
      String? token;
      if (stored != null && sent != 'Bearer $stored') {
        token = stored;
      } else {
        _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
        token = await _refreshing;
      }
      if (token == null) {
        handler.next(err);
        return;
      }
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (error) {
      // Preserve connection failures: they do not prove the session expired.
      handler.next(error);
    } catch (error) {
      handler.next(DioException(requestOptions: request, error: error));
    }
  }

  Future<String?> _refresh() async {
    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null) {
      await _expire();
      return null;
    }
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'expiresInMins': ApiConfig.tokenLifetimeMins,
        },
      );
      final access = response.data?['accessToken'] as String?;
      final refresh = response.data?['refreshToken'] as String?;
      if (access == null || refresh == null) {
        await _expire();
        return null;
      }
      // Do not resurrect a session that was logged out during refresh.
      if (await tokens.readRefreshToken() != refreshToken) return null;
      await tokens.save(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // A rejected refresh token is terminal. Network trouble is not.
      if (status == 400 || status == 401 || status == 403) {
        await _expire();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _expire() async {
    try {
      await tokens.clear();
    } finally {
      onSessionExpired();
    }
  }
}

/// Debug-only logger that never prints headers, bodies or tokens.
class SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[api] ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[api] ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[api] ERROR ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.uri.path}',
    );
    handler.next(err);
  }
}
