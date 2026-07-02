import 'dart:async';
import 'package:flutter/material.dart';
import 'core/routes/app_router.dart'; // استيراد نظام التوجيه المحدث

void main() {
  runApp(const HussamCoreApp());
}

class HussamCoreApp extends StatelessWidget {
  const HussamCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hussam Core AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff090a0f), // خلفية داكنة فاخرة
        primaryColor: const Color(0xff00f5d4),            // اللون النيوني الفيروزي
        hintColor: const Color(0xff7b2cbf),               // اللون الأرجواني الإمبراطوري
        fontFamily: 'monospace',
      ),
      initialRoute: AppRouter.coreHub, // المسار الرئيسي المعتمد في الـ Router
      routes: AppRouter.routes,
    );
  }
}

/// الواجهة المركزية للمنصة المستوردة داخل الـ AppRouter
class MainControlCenterScreen extends StatefulWidget {
  const MainControlCenterScreen({super.key});

  @override
  State<MainControlCenterScreen> createState() => _MainControlCenterScreenState();
}

class _MainControlCenterScreenState extends State<MainControlCenterScreen> {
  late Timer _telemetryTimer;
  int _syncTick = 0;
  double _matrixLoad = 12.4;
  
  // سجل مراقبة الأنظمة اللحظي (Live Audits)
  final List<String> _liveLogs = [
    "• Initializing secure tunnel integration via Cloudflare Secure Mesh...",
    "• Laravel Seeders data verified and structured successfully.",
    "• Flutter AppRouter connection: RESOLVED."
  ];

  @override
  void initState() {
    super.initState();
    // محاكاة المزامنة اللحظية كل 100 ملي ثانية بناءً على إعدادات الـ Seeder (sync_interval_ms = 100)
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _syncTick++;
        if (_syncTick % 10 == 0) {
          _matrixLoad = 12.4 + (_syncTick % 3 == 0 ? 0.5 : -0.3);
          if (_liveLogs.length > 5) _liveLogs.removeAt(0);
          _liveLogs.add("• Telemetry Sync Wave #$_syncTick: Matrix stream operational.");
        }
      });
    });
  }

  @override
  void dispose() {
    _telemetryTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff090a0f), Color(0xff121424)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1️⃣ ترويسة الهوية والنظام (System Header)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HUSSAM CORE AI',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Color(0xff00f5d4),
                            letterSpacing: 1.5
                          ),
                        ),
                        Text(
                          'Mesh Routing: Cloudflare Secure Mesh Active',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xff00f5d4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xff00f5d4).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar, color: Color(0xff00f5d4), size: 14),
                          SizedBox(width: 6),
                          Text('CORE ALIVE', style: TextStyle(color: Color(0xff00f5d4), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // 2️⃣ شاشة مراقبة الأداء اللحظي (Matrix Telemetry)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xff7b2cbf), Color(0xff3c096c)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xff7b2cbf).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('معدل معالجة مصفوفة البيانات الرقمية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${_matrixLoad.toStringAsFixed(1)} GB/s', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                      const Icon(Icons.blur_on_rounded, color: Colors.white, size: 40),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 3️⃣ قطاعات النظام المستوردة من الـ Laravel Seeders
                const Text(
                  'القطاعات المعتمدة في النواة (System Sectors)',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // قطاع 1
                _buildSectorCard(
                  title: 'Data Intelligence & Core Matrix',
                  subtitle: 'Slug: data-intelligence-core',
                  details: 'Auth: matrix-provider-secure • Regions: YE, SA, AE',
                  icon: Icons.hub_rounded,
                  color: const Color(0xff00f5d4),
                ),
                
                // قطاع 2
                _buildSectorCard(
                  title: 'Clinical Intelligence & Medical Management Core',
                  subtitle: 'Slug: clinical-intelligence-medical',
                  details: 'Compliance: Encrypted Data Privacy Standard • Lab Scope: Active',
                  icon: Icons.medical_services_outlined,
                  color: Colors.blueAccent,
                ),
                
                // قطاع 3
                _buildSectorCard(
                  title: 'Enterprise Resource & Luxury Ledger Operations',
                  subtitle: 'Slug: enterprise-resource-ledgers',
                  details: 'Aesthetic: Minimalist Luxury Dark • Currency: YER',
                  icon: Icons.auto_awesome_mosaic_outlined,
                  color: const Color(0xffffb703),
                ),
                
                const SizedBox(height: 20),
                
                // 4️⃣ اختبار موجه المسارات البرمجي (AppRouter Test Operations)
                const Text(
                  'أدوات اختبار موجه المسارات الذكي (AppRouter Matrix)',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff121424), side: const BorderSide(color: Colors.white10)),
                        onPressed: () => AppRouter.navigateToRoleDashboard(context, 'merchant'),
                        icon: const Icon(Icons.storefront, size: 16, color: Color(0xff00f5d4)),
                        label: const Text('لوحة التاجر', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff121424), side: const BorderSide(color: Colors.white10)),
                        onPressed: () => AppRouter.navigateToRoleDashboard(context, 'customer'),
                        icon: const Icon(Icons.person_outline, size: 16, color: Color(0xff7b2cbf)),
                        label: const Text('لوحة العميل', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                
                // 5️⃣ شاشة المراقبة البرمجية اللحظية (Live Core Logs Monitor)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Text('AI Matrix Audits & Live Traces (Interval: 100ms)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      ..._liveLogs.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(log, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
                      )),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectorCard({
    required String title, 
    required String subtitle, 
    required String details, 
    required IconData icon, 
    required Color color
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
