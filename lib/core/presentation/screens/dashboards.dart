import 'package:flutter/material.dart';
import 'ledger_view.dart'; // 🚀 تم ربط نظام المقاصة المالية اللحظية لـ Hussam Core AI هنا

/// 🏪 لوحة تحكم التاجر الفاخرة (Luxury Merchant Dashboard)
class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090a0f),
      appBar: AppBar(
        title: const Text('MERCHANT CONTROL PANEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xff090a0f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xff00f5d4)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترحيب فخم بالتاجر
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xff00f5d4),
                  child: Icon(Icons.storefront_rounded, color: Colors.black),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً بك يا شريك النجاح', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('حساب تاجر معتمد في اليمن (Active Merchant)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // ⚡ الكارت المالي التفاعلي المرتبط لحظياً بـ LedgerView
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LedgerView(userId: 1), // انتقال فوري وصاروخي لكشف الحساب والعمليات
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xff00f5d4).withOpacity(0.05), Colors.white.withOpacity(0.01)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff00f5d4).withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff00f5d4).withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الرصيد المتاح (Luxury Ledger Balance)', style: TextStyle(color: Colors.white50, fontSize: 12)),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xff00f5d4), size: 12),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text('4,750,000 YER', style: TextStyle(color: Color(0xff00f5d4), fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('مبيعات اليوم: +120,000 YER (اضغط للتفاصيل اللحظية)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 16),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            
            const Text('الإجراءات السريعة للتاجر:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // كروت الخدمات السريعة
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildQuickActionCard(Icons.add_box_outlined, 'إضافة منتج جديد', 'Sector: Luxury Ledger', const Color(0xff00f5d4)),
                  _buildQuickActionCard(Icons.analytics_outlined, 'تقارير المبيعات الذكية', 'AI Optimization', Colors.blueAccent),
                  _buildQuickActionCard(Icons.qr_code_scanner_rounded, 'مسح كود المبيعات', 'Instant Routing', const Color(0xff7b2cbf)),
                  _buildQuickActionCard(Icons.support_agent_rounded, 'الدعم الفني والوكلاء', 'Yemen Core Support', Colors.orangeAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, String tag, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tag, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
            ],
          )
        ],
      ),
    );
  }
}

/// 👤 لوحة تحكم العميل الأنيقة (Elegant Customer Dashboard)
class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090a0f),
      appBar: AppBar(
        title: const Text('CUSTOMER PORTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xff090a0f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xff7b2cbf)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ملف العميل
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xff7b2cbf),
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً بك في هويتك الرقمية', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('معرف العميل الموحد (Unified Client Matrix)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // كارت المزامنة الصحية والبيانات (Clinical & Data Intelligence Sync)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xff121424), Color(0xff1a1d36)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مزامنة البيانات الصحية والطبية', style: TextStyle(color: Colors.white90, fontSize: 13, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Unit Clinic', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)), // تم تصحيح اللون هنا ليعمل 100%
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCustomerStatusRow(Icons.favorite_rounded, 'الحالة الحيوية:', 'مستقرة ومحدثة بالذكاء الاصطناعي', Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildCustomerStatusRow(Icons.biotech_rounded, 'الفحوصات المخبرية المعلقة:', 'لا يوجد - تم رفع كافة النتائج', Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            const Text('الخدمات والقطاعات المتاحة لك:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // قائمة خدمات العميل
            _buildCustomerServiceTile(Icons.wallet_rounded, 'المحفظة الرقمية المدفوعة', 'إرسال واستقبال الأموال محلياً', const Color(0xfff15bb5)),
            _buildCustomerServiceTile(Icons.medication_liquid_rounded, 'الاستشارات الذكية الفورية', 'مدعوم بنواة Clinical Intelligence', Colors.blueAccent),
            _buildCustomerServiceTile(Icons.security_rounded, 'تأمين حماية الهوية الرقمية', 'تشفير كامل عبر Cloudflare Secure Mesh', const Color(0xff00f5d4)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStatusRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCustomerServiceTile(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 12),
        ],
      ),
    );
  }
}
