// flutter_client/lib/core/network/supabase_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class SupabaseService {
  final ApiClient apiClient;
  final String restEndpointPrefix;
  final String storageEndpointPrefix;
  final Map<String, String>? defaultHeaders;

  SupabaseService({
    required this.apiClient,
    required this.restEndpointPrefix,
    required this.storageEndpointPrefix,
    this.defaultHeaders,
  });

  /// Generic Supabase-style REST select (GET) on a table.
  /// Example: GET /rest/v1/{table}?select=*
  Future<List<dynamic>> selectTable(String table, {String select = '*', Map<String, dynamic>? query}) async {
    final path = '$restEndpointPrefix/$table';
    final params = <String, dynamic>{'select': select, ...?query};
    final opts = Options(headers: {...?defaultHeaders, 'Accept': 'application/json'});
    try {
      final resp = await apiClient.get(path, queryParameters: params, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Insert rows into table. Returns inserted rows (if server supports return=representation).
  Future<List<dynamic>> insert(String table, List<Map<String, dynamic>> rows, {bool upsert = false, String? onConflict}) async {
    final path = '$restEndpointPrefix/$table';
    final headers = {
      ...?defaultHeaders,
      'Prefer': upsert ? 'return=representation,resolution=merge-duplicates' : 'return=representation',
      'Content-Type': 'application/json',
    };
    final opts = Options(headers: headers);
    // If onConflict provided, attach query parameter
    String qs = '';
    if (onConflict != null && onConflict.isNotEmpty) {
      // Supabase uses ?on_conflict=column
      qs = '?on_conflict=$onConflict';
    }
    try {
      final resp = await apiClient.post('$path$qs', data: rows, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Upsert provided records into a table using POST with on_conflict.
  Future<List<dynamic>> upsert(String table, List<Map<String, dynamic>> rows, {required String onConflict}) async {
    return insert(table, rows, upsert: true, onConflict: onConflict);
  }

  /// Update rows using RPC style or direct PATCH if allowed; uses primary key in payload
  Future<List<dynamic>> updateByPk(String table, String pkName, dynamic pkValue, Map<String, dynamic> changes) async {
    final path = '$restEndpointPrefix/$table?$pkName=eq.$pkValue';
    final headers = {...?defaultHeaders, 'Prefer': 'return=representation', 'Content-Type': 'application/json'};
    final opts = Options(headers: headers);
    try {
      final resp = await apiClient.patch(path, data: changes, options: opts);
      return _normalizeData(resp);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Delete by primary key value
  Future<void> deleteByPk(String table, String pkName, dynamic pkValue) async {
    final path = '$restEndpointPrefix/$table?$pkName=eq.$pkValue';
    try {
      await apiClient.delete(path);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// Upload a file to storage bucket (simple wrapper).
  Future<String> uploadFile(String bucketPath, String fileName, List<int> bytes, {required String contentType}) async {
    final path = '$storageEndpointPrefix/$bucketPath';
    try {
      final resp = await apiClient.uploadFile(path, 'file', bytes, fileName, contentType: contentType);
      final data = resp.data;
      if (data is Map && data['Key'] != null) {
        return data['Key'].toString();
      }
      return jsonEncode(data);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  /// High-level sync: upsert a batch of ai_logs (delegated to Supabase table "ai_logs")
  Future<void> syncAiLogsBatch(List<Map<String, dynamic>> logsBatch, {int batchSize = 100}) async {
    final chunks = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < logsBatch.length; i += batchSize) {
      chunks.add(logsBatch.sublist(i, i + batchSize > logsBatch.length ? logsBatch.length : i + batchSize));
    }
    for (final chunk in chunks) {
      try {
        await upsert('ai_logs', chunk, onConflict: 'request_id');
      } catch (e) {
        // On failure, attempt single-record retries to isolate bad payloads
        for (final record in chunk) {
          try {
            await upsert('ai_logs', [record], onConflict: 'request_id');
          } catch (singleErr) {
            // Log and swallow to avoid entire sync failing
            // Integrators should capture these via remote error tracking
            if (kDebugMode) {
              print('Failed to upsert ai_log record: $singleErr');
            }
          }
        }
      }
    }
  }

  /// Helper: Normalize Dio Response to a list of dynamic objects consistently
  List<dynamic> _normalizeData(Response resp) {
    if (resp.data == null) return [];
    if (resp.data is List) return resp.data as List<dynamic>;
    if (resp.data is Map && (resp.data as Map).containsKey('data')) {
      final d = (resp.data as Map)['data'];
      if (d is List) return d;
      return [d];
    }
    // Fallback to wrapping single object
    return [resp.data];
  }

  /// Map/unwrap errors into ApiException for callers to handle
  Exception _wrapError(Object e) {
    if (e is ApiException) return e;
    if (e is DioError) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = (body is Map && body['message'] != null) ? body['message'] : e.message;
      return ApiException(msg ?? 'Network error', statusCode: status, details: body);
    }
    return ApiException(e.toString());
  }
}
