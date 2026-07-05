// flutter_client/lib/core/network/api_client.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef FutureStringCallback = Future<String?> Function();
typedef FutureRefreshCallback = Future<String?> Function();

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  ApiException(this.message, {this.statusCode, this.details});
  @override
  String toString() => "ApiException: $message (status: $statusCode) ${details ?? ''}";
}

class ApiClient {
  final Dio _dio;
  final FutureStringCallback? tokenProvider;
  final FutureRefreshCallback? tokenRefresher;
  final FutureStringCallback? tenantIdProvider;
  final int _maxRetries;
  final Duration _retryDelayBase;

  // Single-flight refresh completer; null when no refresh in progress
  Completer<String?>? _refreshCompleter;

  ApiClient({
    required String baseUrl,
    this.tokenProvider,
    this.tokenRefresher,
    this.tenantIdProvider,
    int maxRetries = 2,
    Duration retryDelayBase = const Duration(milliseconds: 300),
    bool enableLogging = false,
    Map<String, dynamic>? defaultHeaders,
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 30000),
          sendTimeout: const Duration(milliseconds: 15000),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'HussamClient/1.0',
            ...?defaultHeaders,
          },
        )),
        tokenProvider = tokenProvider,
        tokenRefresher = tokenRefresher,
        tenantIdProvider = tenantIdProvider,
        _maxRetries = maxRetries,
        _retryDelayBase = retryDelayBase {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // FAIL-FAST: if providers are configured but return null, reject early
        try {
          // Tenant requirement: if provider configured, ensure it yields non-null value
          if (tenantIdProvider != null) {
            final tenantId = await tenantIdProvider!();
            if (tenantId == null || tenantId.isEmpty) {
              return handler.reject(DioError(
                requestOptions: options,
                error: ApiException('Missing tenant id (X-Tenant-ID)'),
                type: DioErrorType.unknown,
              ));
            }
            options.headers['X-Tenant-ID'] = tenantId;
          }

          // Auth requirement: if tokenProvider configured, ensure it yields non-null
          if (tokenProvider != null) {
            final token = await tokenProvider!();
            if (token == null || token.isEmpty) {
              return handler.reject(DioError(
                requestOptions: options,
                error: ApiException('Missing auth token'),
                type: DioErrorType.unknown,
              ));
            }
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // If provider throws, surface as error instead of silently continuing
          return handler.reject(DioError(
            requestOptions: options,
            error: ApiException('Provider error: $e'),
            type: DioErrorType.unknown,
          ));
        }

        handler.next(options);
      },
      onError: (err, handler) async {
        final requestOptions = err.requestOptions;
        final extra = requestOptions.extra;
        int retryCount = (extra['retry_count'] as int?) ?? 0;

        // If 401 and we have a refresher, attempt single-flight refresh then retry once
        final status = err.response?.statusCode ?? 0;
        if (status == 401 && tokenRefresher != null) {
          // avoid infinite loops
          if (requestOptions.extra['retried_after_refresh'] == true) {
            return handler.next(err);
          }
          try {
            final newToken = await _performSingleFlightRefresh();
            if (newToken != null && newToken.isNotEmpty) {
              // Update stored token if refresher also stores it; ensure request reuses latest token
              requestOptions.headers['Authorization'] = 'Bearer $newToken';
              requestOptions.extra['retried_after_refresh'] = true;
              try {
                final response = await _dio.fetch(requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(e as DioError);
              }
            } else {
              // Refresh failed; forward original 401
              return handler.next(err);
            }
          } catch (refreshErr) {
            return handler.next(err);
          }
        }

        final shouldRetry = _shouldRetry(err, retryCount);
        if (shouldRetry && retryCount < _maxRetries) {
          // IDEMPOTENCY CHECK: Do not retry unsafe POSTs unless idempotency key or request_id present
          final method = (requestOptions.method ?? 'GET').toUpperCase();
          bool hasIdempotency = false;
          if (requestOptions.headers.containsKey('Idempotency-Key')) {
            hasIdempotency = true;
          } else if (requestOptions.data is Map) {
            final data = requestOptions.data as Map;
            if (data.containsKey('request_id') && data['request_id'] != null && data['request_id'].toString().isNotEmpty) {
              hasIdempotency = true;
            }
          }

          if (method == 'POST' && !hasIdempotency) {
            // Do not automatically retry unsafe POST without idempotency
            return handler.next(err);
          }

          retryCount++;
          final waitDuration = _computeBackoffDelay(retryCount);
          requestOptions.extra['retry_count'] = retryCount;
          await Future.delayed(waitDuration);

          // Before reissuing, refresh Authorization header from tokenProvider (if available)
          try {
            if (tokenProvider != null) {
              final latestToken = await tokenProvider!();
              if (latestToken != null && latestToken.isNotEmpty) {
                requestOptions.headers['Authorization'] = 'Bearer $latestToken';
              }
            }
          } catch (_) {
            // ignore - will attempt with whatever headers present
          }

          try {
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(e as DioError);
          }
        }

        return handler.next(err);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) {
        debugPrint('ApiClient: $obj');
      }));
    }
  }

  Future<String?> _performSingleFlightRefresh() async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final newToken = await tokenRefresher!();
      // The tokenRefresher should persist the new token to the same store tokenProvider reads from.
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      // ensure to reset completer only after completion
      _refreshCompleter = null;
    }
  }

  bool _shouldRetry(DioError err, int retryCount) {
    if (err.type == DioErrorType.connectionTimeout ||
        err.type == DioErrorType.sendTimeout ||
        err.type == DioErrorType.receiveTimeout ||
        err.type == DioErrorType.unknown ||
        err.error is SocketException) {
      return true;
    }
    final status = err.response?.statusCode ?? 0;
    if (status >= 500 && status < 600) {
      return true;
    }
    if (status == 429) {
      return true;
    }
    return false;
  }

  Duration _computeBackoffDelay(int retryCount) {
    final factor = (1 << (retryCount - 1)); // exponential
    return Duration(
      milliseconds: _retryDelayBase.inMilliseconds * factor,
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.put(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.delete(path, data: data, options: options);
      return response;
    } on DioError catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioError e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (e.type == DioErrorType.cancel) {
      return ApiException('Request cancelled', statusCode: status, details: body);
    }
    if (e.type == DioErrorType.unknown && e.error is SocketException) {
      return ApiException('Network error: ${e.error}', statusCode: status, details: body);
    }
    if (status != null && status >= 400 && status < 600) {
      final message = (body is Map && body['message'] != null) ? body['message'] : 'HTTP error: $status';
      return ApiException(message, statusCode: status, details: body);
    }
    // If the error contains an ApiException already, surface it
    if (e.error is ApiException) {
      return e.error as ApiException;
    }
    return ApiException(e.message ?? 'Unknown network error', statusCode: status, details: body);
  }

  Dio get dio => _dio;
}

// Helper MediaType class to avoid importing extra packages in minimal contexts
class MediaType {
  final String type;
  final String subtype;
  MediaType(this.type, this.subtype);
  @override
  String toString() => '$type/$subtype';
}
