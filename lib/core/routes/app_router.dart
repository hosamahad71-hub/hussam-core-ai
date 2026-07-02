import 'package:flutter/material.dart';
import '../../../main.dart'; // استدعاء شاشة لوحة التحكم المركزية الفاخرة Hussam Core AI

/// المحرك: Hussam Core AI Engine
/// الوحدة: نظام التوجيه المركزي لملفات واجهات المستخدم (Map Based Router)
class AppRouter {
  
  // تعريف أسماء المسارات الثابتة في النظام
  static const String coreHub = '/';
  static const String login = '/login';
  static const String customerDashboard = '/customer_dashboard';
  static const String merchantDashboard = '/merchant_dashboard';

  /// مصفوفة الخرائط لربط المسارات بالواجهات الحية
  static Map<String, WidgetBuilder> get routes {
    return {
      // ربط المسار الرئيسي بلوحة التحكم الفاخرة التي يترقبها الجميع
      coreHub: (context) => const MainControlCenterScreen(),
      
      // مسارات احتياطية آمنة تمنع انهيار التطبيق أثناء التجربة الحية
      login: (context) => const Scaffold(body: Center(child: Text('Login Page', style: TextStyle(color: Colors.white)))),
      customerDashboard: (context) => const Scaffold(body: Center(child: Text('Customer Dashboard', style: TextStyle(color: Colors.white)))),
      merchantDashboard: (context) => const Scaffold(body: Center(child: Text('Merchant Dashboard', style: TextStyle(color: Colors.white)))),
    };
  }

  /// دالة التوجيه الذكي بناءً على صلاحيات ودور المستخدم
  static void navigateToDashboard(BuildContext context, String role) {
    if (role == 'merchant' || role == 'vendor' || role == 'admin') {
      Navigator.pushReplacementNamed(context, merchantDashboard);
    } else {
      Navigator.pushReplacementNamed(context, customerDashboard);
    }
  }
}
