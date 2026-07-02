import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: نقطة الانطلاق المركزية للتطبيق والرابط الأساسي لجميع الواجهات والمسارات
void main() {
  // ملاحظة: هنا مستقبلاً سيتم إضافة سطر تهيئة الاتصال بـ Supabase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hussam Core AI',
      debugShowCheckedModeBanner: false,
      
      // 1. تفعيل السمة المظلمة الفخمة (Dark Theme) لتتناسب مع هوية المنصة المستقبلية
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        primaryColor: Colors.blueAccent,
      ),
      
      // 2. تحديد شاشة الانطلاق الأولى (ستفتح الشاشة تلقائياً على صفحة تسجيل الدخول)
      initialRoute: AppRouter.login,
      
      // 3. ربط خريطة التنقل والمسارات الذكية التي برمجناها في ملف الـ Router
      routes: AppRouter.routes,
    );
  }
}
