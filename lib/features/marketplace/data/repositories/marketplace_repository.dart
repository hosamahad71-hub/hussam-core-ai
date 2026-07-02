import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../../../../core/network/supabase_service.dart';

class MarketplaceRepository {
  final SupabaseClient _client = SupabaseService().client;

  // مشيد مرن لمنع أخطاء التمرير القديمة تماماً
  MarketplaceRepository([dynamic apiClient]);

  // الدالة الرئيسية المعتمدة داخل الـ Bloc لجلب البيانات
  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      // مرونة كاملة لمنع كراش التطبيق في حالة غياب الجداول مؤقتاً
      return [];
    }
  }

  // جسر ربط إضافي لضمان عدم حدوث أي تعارض مسميات مستقبلي
  Future<List<ProductModel>> fetchLiveProducts() => fetchProducts();
}
