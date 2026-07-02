import 'package:flutter/material.dart';
import 'dart:ui';

void main() {
  runApp(const HussamCoreAIApp());
}

class HussamCoreAIApp extends StatelessWidget {
  const HussamCoreAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hussam Core AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff090a0f), // لون الفضاء العميق العتيق
        primaryColor: const Color(0xff00f5d4), // نيون سيان لإشارات النظام النشطة
        hintColor: const Color(0xff7b2cbf), // نيون بنفسجي للوحدات المتقدمة
      ),
      home: const MainControlCenterScreen(),
    );
  }
}

class MainControlCenterScreen extends StatefulWidget {
  const MainControlCenterScreen({Key? key}) : super(key: key);

  @override
  State<MainControlCenterScreen> createState() => _MainControlCenterScreenState();
}

class _MainControlCenterScreenState extends State<MainControlCenterScreen> with SingleTickerProviderStateMixin {
  int selectedSectorIndex = 0;
  late AnimationController _pulseController;

  // مصفوفة البيانات الذكية المحاكية للنظام بالكامل لعرضها فوراً للمستخدمين
  final List<Map<String, dynamic>> sectorsMatrix = [
    {
      'name': 'Data Intelligence & Core Matrix',
      'icon': Icons.psychology_rounded,
      'status': 'Active Node',
      'color': const Color(0xff00f5d4),
      'details': {
        'Metrics': ['AI Accuracy: 99.4%', 'Tunnel Routing: Cloudflare Secure Mesh', 'Observability: High Trace Logging'],
        'Live Logs': ['[INFO] Processing neural data map...', '[SUCCESS] Connection securely routed to Core AI.']
      }
    },
    {
      'name': 'Clinical Intelligence (Unit Clinic)',
      'icon': Icons.healing_rounded,
      'status': 'Synchronized',
      'color': const Color(0xff00bbf9),
      'details': {
        'Metrics': ['Clinic ID: Unit Clinic Main', 'Compliance: Encrypted Privacy Standard', 'Lab Status: Active Tracking'],
        'Live Logs': ['[SYNC] Case status matrix connected.', '[READY] Waiting for laboratory routing signal...']
      }
    },
    {
      'name': 'Enterprise Resource & Luxury Ledger',
      'icon': Icons.account_balance_wallet_rounded,
      'status': 'Secure Luxury Mode',
      'color': const Color(0xfff15bb5),
      'details': {
        'Metrics': ['Aesthetic: Minimalist Luxury Dark', 'Currency Default: YER (Yemeni Rial)', 'Multi-Tenant: Scoped & Encrypted'],
        'Live Logs': ['[SECURE] Ledger balance ledger initialized.', '[AUDIT] Zero-knowledge accounting precision set to 2.']
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    // إعداد حركة النبض الذكية للمدارات والمؤشرات لإعطاء شعور بالحياة داخل النظام
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var activeSector = sectorsMatrix[selectedSectorIndex];

    return Scaffold(
      body: Stack(
        children: [
          // خلفية كونية متدرجة مع النيون الأخاذ
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeSector['color'].withOpacity(0.15),
                blurRadius: 120,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff7b2cbf).withOpacity(0.1),
                blurRadius: 100,
              ),
            ),
          ),
          
          // الواجهة الرئيسية
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر الاحترافي الفاخر للمنصة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HUSSAM CORE AI',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.black, letterSpacing: 2, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xff00f5d4).withOpacity(_pulseController.value),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff00f5d4),
                                          blurRadius: 10 * _pulseController.value,
                                        )
                                      ]
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ENGINE OPERATIONAL (YEMEN CORE)',
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Color(0xff00f5d4)),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Text(
                    'اختر قطاع النظام للمعاينة والتجربة الفورية:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white90),
                  ),
                  const SizedBox(height: 15),

                  // قائمة أزرار الوحدات والقطاعات المتاحة للتنقل والتجربة التفاعلية
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sectorsMatrix.length,
                      itemBuilder: (context, index) {
                        bool isSelected = index == selectedSectorIndex;
                        var sector = sectorsMatrix[index];
                        return GestureDetector(
                          onTap: () => setState(() => selectedSectorIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 150,
                            margin: const EdgeInsets.only(right: 12, bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? sector['color'].withOpacity(0.12) : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? sector['color'] : Colors.white.withOpacity(0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: sector['color'].withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))
                              ] : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(sector['icon'], color: isSelected ? sector['color'] : Colors.white60, size: 28),
                                Text(
                                  sector['name'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11, 
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.white70
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // لوحة عرض تفاصيل القطاع المختار بتأثير زجاجي (Glassmorphic Core Console)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activeSector['name'],
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: activeSector['color'].withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: activeSector['color'].withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      activeSector['status'],
                                      style: TextStyle(fontSize: 10, color: activeSector['color'], fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              const Divider(height: 30, color: Colors.white10),
                              
                              const Text('المعايير المتقدمة للوحدة (System Architecture Matrix):', style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              
                              // جلب المعايير والمواصفات لكل قطاع
                              ...(activeSector['details']['Metrics'] as List<String>).map((metric) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.stop_circle_rounded, size: 12, color: activeSector['color']),
                                    const SizedBox(width: 10),
                                    Text(metric, style: const TextStyle(fontSize: 13, color: Colors.white90)),
                                  ],
                                ),
                              )).toList(),

                              const SizedBox(height: 25),
                              const Text('سجل العمليات الفوري والمحاكاة الذكية (Live Debug Terminal):', style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),

                              // محاكاة الشاشة السوداء (Terminal) لرؤية الأكواد والعمليات الخلفية تعمل
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: ListView.builder(
                                    itemCount: (activeSector['details']['Live Logs'] as List<String>).length,
                                    itemBuilder: (context, i) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Text(
                                          activeSector['details']['Live Logs'][i],
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xffa2aebb)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 15),
                              // زر تفاعلي يحاكي معالجة الأوامر الفورية بلمسة يد الدكتور حسام
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Hussam Core AI: Executing microservices for ${activeSector['name']}...'),
                                        backgroundColor: activeSector['color'].withOpacity(0.8),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: activeSector['color'],
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  child: const Text('تشغيل وفحص العمليات الحية ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
