import 'package:uuid/uuid.dart';

class IdempotencyManager {
  static final Uuid _uuid = Uuid();

  /**
   * توليد معرّف حتمي فريد (v4 UUID) لكل معاملة قبل إرسالها للباكيند.
   */
  static String generateRequestId() {
    return _uuid.v4();
  }

  /**
   * تجهيز الهيدرز الافتراضية للطلب وحقن معرّف الحتمية السيادي.
   */
  static Map<String, String> getHeadersWithIdempotency(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Request-ID': generateRequestId(), // التوقيع الحتمي لمنع التكرار في تعز
    };
  }
}
