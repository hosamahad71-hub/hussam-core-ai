import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  // الإعدادات الافتراضية للربط مع سيرفر الـ Laravel أو الـ Gateway المستقبلي
  ApiClient({Dio? dio})
      : _dio = dio ?? Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8001/api/v4', // بوابتك الحالية للمحرك
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _initializeInterceptors();
  }

  // إعداد المراقبة الذكية للطلبات (لوضع التوكنز وتتبع الأخطاء)
  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // هنا سيتم حقن الـ Bearer Token تلقائياً عند تسجيل دخول المستخدم اليمني
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // إدارة الأخطاء المركزية (مثلاً: انقطاع الشبكة أو خطأ سيرفر)
          return handler.next(e);
        },
      ),
    );
  }

  // دالة جلب البيانات العامة (GET) مثل المنتجات أو الخدمات
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // دالة إرسال البيانات (POST) مثل تنفيذ العقود أو الطلبات الجديدة
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
