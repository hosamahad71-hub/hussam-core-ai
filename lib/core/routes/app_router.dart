import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/marketplace/presentation/home_dashboard.dart';
import '../../features/merchant/presentation/merchant_dashboard.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: نظام التحكم المركزي بمسارات التنقل والتوجيه بناءً على الهوية (Role-Based Router)
class AppRouter {
  // تعريف أسماء المسارات الثابتة في النظام
  static const String login = '/login';
  static const String customerDashboard = '/customer_dashboard';
  static const String merchantDashboard = '/merchant_dashboard';

  /// خريطة المسارات لربط المسميات بالواجهات الحقيقية
  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      customerDashboard: (context) => const HomeDashboard(),
      merchantDashboard: (context) => const MerchantDashboard(),
    };
  }

  /// الدالة الذكية للتوجيه الفوري بناءً على دور المستخدم (Role) القادم من الـ Backend
  static void navigateToRoleDashboard(BuildContext context, String role) {
    if (role == 'merchant' || role == 'vendor' || role == 'admin') {
      // توجيه فوري إلى لوحة تحكم التجار وإغلاق صفحة الدخول لمنع الرجوع
      Navigator.pushNamedAndRemoveUntil(context, merchantDashboard, (route) => false);
    } else {
      // توجيه تلقائي لعموم المستخدمين إلى المتجر الرئيسي
      Navigator.pushNamedAndRemoveUntil(context, customerDashboard, (route) => false);
    }
  }
}
