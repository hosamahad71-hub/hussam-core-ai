import 'package:flutter/material.dart';
import '../bloc/marketplace_bloc.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: لوحة التحكم الرئيسية للمتجر والخدمات (Home Dashboard UI) بتصميم نيون مستقبلي
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _LoginPageState extends State<HomeDashboard> {
class _HomeDashboardState extends State<HomeDashboard> {
  final MarketplaceBloc _bloc = MarketplaceBloc();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // تحميل البيانات فور فتح الشاشة
  void _loadData() {
    _bloc.fetchMarketplaceItems().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _bloc.state;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12), // الخلفية الداكنة الفخمة الثابتة للمنصة
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181F),
        elevation: 0,
        title: const Text(
          'متجر الخدمات الذكية',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: Colors.blueAccent,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(MarketplaceState state) {
    if (state is MarketplaceLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (state is MarketplaceError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MarketplaceLoaded) {
      final items = state.items;

      if (items.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد خدمات أو منتجات معروضة حالياً',
            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
          ),
        );
      }

      // عرض البيانات على شكل شبكة كروت عصرية (Grid View)
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // كرتين في كل سطر
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMarketplaceCard(item);
        },
      );
    }

    return const SizedBox();
  }

  // تصميم الكارت المستقبلي عالي الجودة
  Widget _buildMarketplaceCard(dynamic item) {
    final String name = item['name'] ?? 'خدمة غير مسمى';
    final double price = (item['price'] ?? 0.0).toDouble();
    final String description = item['description'] ?? 'لا يوجد وصف متاح لهذه الخدمة حالياً.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181F), // كرت داكن
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1), // إطار ناعم جداً
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة افتراضية فخمة للخدمة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.token_outlined, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(height: 12),
          // اسم الخدمة
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 4),
          // وصف مختصر
          Expanded(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo'),
            ),
          ),
          const SizedBox(height: 8),
          // السعر وزر الإجراء
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$$price',
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blueAccent,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  onPressed: () {
                    // الانتقال لتفاصيل الخدمة أو طلبها مستقبلاً
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
