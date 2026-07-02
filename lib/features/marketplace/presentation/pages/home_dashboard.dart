import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_state.dart';
import '../bloc/marketplace_event.dart';
import '../../data/models/product_model.dart';

class MainEnterpriseDashboard extends StatefulWidget {
  const MainEnterpriseDashboard({super.key});

  @override
  State<MainEnterpriseDashboard> createState() => _MainEnterpriseDashboardState();
}

class _MainEnterpriseDashboardState extends State<MainEnterpriseDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // تفعيل محرك جلب البيانات التلقائي فور استقرار الواجهة أمام المتابعين
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MarketplaceBloc>().add(FetchProducts());
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HUSSAM PLATFORM',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'YEMEN ECOSYSTEM v4.0',
                        style: GoogleFonts.sourceCodePro(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.6),
                              blurRadius: 4 + (_pulseController.value * 8),
                              spreadRadius: _pulseController.value * 4,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                  builder: (context, state) {
                    if (state is MarketplaceLoading) {
                      return _buildNeonShimmerLoader();
                    } else if (state is MarketplaceLoaded) {
                      if (state.products.isEmpty) {
                        return _buildGrid(_getMockProducts());
                      }
                      return _buildGrid(state.products);
                    }
                    return _buildGrid(_getMockProducts());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonShimmerLoader() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GridView.builder(
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF161B22),
                  const Color(0xFF21262D),
                  _pulseController.value,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1 * _pulseController.value),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle)),
                  Container(width: 100, height: 12, color: Colors.white10),
                  Container(width: 60, height: 12, color: Colors.white10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrid(List<ProductModel> products) {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.layers_rounded, color: Color(0xFF00E5FF)),
              Text(
                product.name,
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${product.price}', style: GoogleFonts.sourceCodePro(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white30),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<ProductModel> _getMockProducts() {
    return [
      ProductModel(id: 1, name: 'بوابة عدن الرقمية', price: 250.0, description: 'بوابة سيادية ذكية حرة', isAvailable: true),
      ProductModel(id: 2, name: 'حزمة صنعاء اللوجستية', price: 420.0, description: 'إدارة سلاسل الإمداد الموحدة', isAvailable: true),
      ProductModel(id: 3, name: 'مستودع تعز السيادي', price: 180.0, description: 'نظام إدارة التخزين الذكي الأمني', isAvailable: true),
      ProductModel(id: 4, name: 'شريان حضرموت الذكي', price: 590.0, description: 'منظومة الربط السحابي والتدفق الحي', isAvailable: true),
    ];
  }
}
