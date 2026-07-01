import 'package:supabase_flutter/supabase_flutter.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: محرك إدارة البيانات والحالات للمتجر الذكي والخدمات (Marketplace Engine)

// ---------------------------------------------------------------------------
// 1. حالات المتجر (Marketplace States)
// ---------------------------------------------------------------------------
abstract class MarketplaceState {}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<dynamic> items;
  MarketplaceLoaded(this.items);
}

class MarketplaceError extends MarketplaceState {
  final String message;
  MarketplaceError(this.message);
}

// ---------------------------------------------------------------------------
// 2. المحرك الرئيسي لإدارة العمليات (Marketplace Controller)
// ---------------------------------------------------------------------------
class MarketplaceBloc {
  final SupabaseClient _client = Supabase.instance.client;

  // تعريف الحالة الابتدائية
  MarketplaceState _state = MarketplaceInitial();
  MarketplaceState get state => _state;

  // دالة جلب المعروضات والخدمات ديناميكياً من قاعدة البيانات
  Future<MarketplaceState> fetchMarketplaceItems() async {
    _state = MarketplaceLoading();
    try {
      // جلب البيانات من جدول الخدمات أو المنتجات المخصص في Backend
      final response = await _client
          .from('services') // اسم الجدول المركزي للخدمات والمنتجات
          .select('*')
          .order('id', ascending: false);

      if (response != null && response is List) {
        _state = MarketplaceLoaded(response);
      } else {
        _state = MarketplaceLoaded([]);
      }
    } catch (e) {
      _state = MarketplaceError('فشل جلب البيانات: ${e.toString()}');
    }
    return _state;
  }

  // دالة إضافة خدمة أو منتج جديد للمتجر (خاص بالتاجر / الإدارة)
  Future<bool> addNewItem({
    required String name,
    required double price,
    required String description,
  }) async {
    try {
      await _client.from('services').insert({
        'name': name,
        'price': price,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
