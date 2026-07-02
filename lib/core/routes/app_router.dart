import 'package:flutter/material.dart';
import '../../../main.dart'; 
import '../presentation/screens/dashboards.dart'; // استدعاء شاشات لوحة التحكم الحقيقية الفاخرة

class AppRouter {
  static const String coreHub = '/';
  static const String login = '/login';
  static const String customerDashboard = '/customer_dashboard';
  static const String merchantDashboard = '/merchant_dashboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      coreHub: (context) => const MainControlCenterScreen(),
      customerDashboard: (context) => const CustomerDashboardScreen(), // الربط الحي للشاشة
      merchantDashboard: (context) => const MerchantDashboardScreen(), // الربط الحي للشاشة
      login: (context) => const Scaffold(body: Center(child: Text('Login Page'))),
    };
  }

  // دالة التنقل المركزي لربط أزرار الفحص في الشاشة الرئيسية بنجاح وثبات
  static void navigateToRoleDashboard(BuildContext context, String role) {
    if (role == 'merchant' || role == 'vendor' || role == 'admin') {
      Navigator.pushReplacementNamed(context, merchantDashboard);
    } else {
      Navigator.pushReplacementNamed(context, customerDashboard);
    }
  }
}
