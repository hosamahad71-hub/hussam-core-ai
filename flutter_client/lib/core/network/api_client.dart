// flutter_client/lib/core/network/api_client.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef FutureStringCallback = Future<String?> Function();

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
  final FutureStringCallback? tenantIdProvider;
  final int _maxRetries;
  final Duration _retryDelayBase;

  ApiClient({
    required String baseUrl,
    this.tokenProvider,
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
        tenantIdProvider = tenantIdProvider,
        _maxRetries = maxRetries,
        _retryDelayBase = retryDelayBase {
    // Authentication & tenant interceptor
    _dio.interceptors.add(QueuedInterceptorsWrapper(onRequest: (options, handler) async {
      try {
        // Attach tenant header
        if (tenantIdProvider != null) {
          final tenantId = await tenantIdProvider!();
          if (tenantId != null && tenantId.isNotEmpty) {
            options.headers['X-Tenant-ID'] = tenantId;
          }
        }

        // Attach auth header
        if (tokenProvider != null) {
          final token = await tokenProvider!();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
      } catch (e) {
        // If provider fails, allow request to proceed without blocking
        if (kDebugMode) {
          print('ApiClient interceptor provider error: $e');
        }
      }
      handler.next(options);
    }, onError: (err, handler) async {
      // Automatic retry logic for transient network errors and 5xx responses
      final requestOptions = err.requestOptions;
      final extra = requestOptions.extra;
      int retryCount = (extra['retry_count'] as int?) ?? 0;

      final shouldRetry = _shouldRetry(err, retryCount);
      if (shouldRetry && retryCount < _maxRetries) {
        retryCount++;
        final waitDuration = _computeBackoffDelay(retryCount);
        requestOptions.extra['retry_count'] = retryCount;
        await Future.delayed(waitDuration);
        try {
          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e as DioError);
        }
      }

      return handler.next(err);
    }, onResponse: (response, handler) {
      handler.next(response);
    }));

    // Optional logging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) {
        debugPrint('ApiClient: $obj');
      }));
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
    // Do not retry on 4xx except 429 Too Many Requests
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

  Future<Response> uploadFile(String path, String fieldName, List<int> bytes, String filename, {String contentType = 'application/octet-stream'}) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename, contentType: MediaType(contentType.split('/')[0], contentType.split('/').last)),
    });

    try {
      final response = await _dio.post(path, data: formData, options: Options(headers: {'Content-Type': 'multipart/form-data'}));
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
    return ApiException(e.message ?? 'Unknown network error', statusCode: status, details: body);
  }

  /// Expose underlying Dio for advanced usage
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
