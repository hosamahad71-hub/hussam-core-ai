import 'package:flutter/material.dart';
import '../../features/marketplace/presentation/pages/home_dashboard.dart';
import '../../features/marketplace/presentation/pages/merchant_dashboard.dart';
import '../../features/marketplace/presentation/pages/logistics_dashboard.dart';

class AppNavigationHub extends StatefulWidget {
  const AppNavigationHub({super.key});

  @override
  State<AppNavigationHub> createState() => _AppNavigationHubState();
}

class _AppNavigationHubState extends State<AppNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MainEnterpriseDashboard(),
    const MerchantEnterpriseDashboard(),
    const LogisticsEnterpriseDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'لوحة التاجر',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'اللوجستيات',
          ),
        ],
      ),
    );
  }
}
