import 'package:supabase_flutter/supabase_flutter.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: الخدمة المركزية لإدارة الاتصال بقاعدة البيانات والمصادقة وتحديد الصلاحيات
class SupabaseService {
  // نسخة منفردة (Singleton) لضمان استخدام اتصال واحد في كل التطبيق
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// التحقق مما إذا كان هناك مستخدم مسجل حالياً
  User? get currentUser => _client.auth.currentUser;

  /// التحقق من حالة تسجيل الدخول (تدفق فوري)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// 1. ميزة تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('خطأ في المصادقة: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء تسجيل الدخول: $e');
    }
  }

  /// 2. ميزة تسجيل حساب جديد (للزبائن أو التجار)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'customer', // القيمة الافتراضية زبون
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('خطأ في إنشاء الحساب: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع أثناء التسجيل: $e');
    }
  }

  /// 3. ميزة جلب دور/صلاحية المستخدم (Role-Based Routing)
  /// تقرأ الدور مباشرة من جدول المستخدمين المخصص في الـ Backend
  Future<String> getUserRole(String userId) async {
    try {
      final data = await _client
          .from('users') 
          .select('role')
          .eq('id', userId)
          .single();

      return data['role'] ?? 'customer';
    } catch (e) {
      // في حال حدوث أي خطأ، نعيد الصلاحية الأقل (زبون) لحماية النظام
      return 'customer';
    }
  }

  /// 4. تسجيل الخروج وإنهاء الجلسة
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('خطأ أثناء تسجيل الخروج: $e');
    }
  }
}
