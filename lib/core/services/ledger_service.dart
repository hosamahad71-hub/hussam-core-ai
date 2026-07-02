import 'dart:convert';
import 'package:http/http.dart' as http;

class LedgerService {
  // الرابط الأساسي للسيرفر - قم بتغييره لاحقاً ليتوافق مع رابط السيرفر الفعلي أو الـ IP الخاص بك
  static const String baseUrl = 'https://your-domain.com/api/v1/matrix';

  /// 1. جلب كشف الحساب المالي اللحظي للمستخدم
  Future<Map<String, dynamic>> getLedger(int userId) async {
    final Uri url = Uri.parse('$baseUrl/ledger/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'فشل في جلب البيانات المادية: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'خطأ في الاتصال بالشبكة الأساسية: $e'
      };
    }
  }

  /// 2. إرسال عملية مالية جديدة (سحب أو إيداع) من واجهة المستخدم إلى الـ Backend
  Future<Map<String, dynamic>> recordTransaction({
    required int userId,
    required String type, // 'credit' أو 'debit'
    required double amount,
    String? sector,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final Uri url = Uri.parse('$baseUrl/ledger/transaction');

    // تجهيز الحقول لتتطابق تماماً مع الـ Validation الخاص بـ Laravel
    final Map<String, dynamic> bodyData = {
      'user_id': userId,
      'type': type,
      'amount': amount,
      if (sector != null) 'sector': sector,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'فشل تسجيل العملية المادية.'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'فشل الاتصال بالخادم، تحقق من استقرار الشبكة: $e'
      };
    }
  }
}
