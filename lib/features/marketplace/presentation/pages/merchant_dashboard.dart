import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantEnterpriseDashboard extends StatelessWidget {
  const MerchantEnterpriseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        'MERCHANT CONTROL',
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFF7000FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'حساب التاجر الموحد',
                        style: GoogleFonts.cairo(
                          color: Colors.white30,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF)),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF161B22), const Color(0xFF1F2631).withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7000FF).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي العوائد الصافية',
                      style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$14,850.00',
                      style: GoogleFonts.sourceCodePro(
                        color: const Color(0xFF00E5FF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat('الطلبات النشطة', '38', Colors.greenAccent),
                        _buildMiniStat('كفاءة الشحن', '98.2%', const Color(0xFF7000FF)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'العمليات الاستراتيجية المتاحة',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildActionCard(Icons.add_box_rounded, 'إضافة منتج سحابي', 'تحديث المخزن الحي'),
                  _buildActionCard(Icons.analytics_rounded, 'التقارير الذكية', 'تحليل التدفق الرقمي'),
                  _buildActionCard(Icons.account_balance_wallet_rounded, 'التسويات النقدية', 'إدارة الديون والأرصدة'),
                  _buildActionCard(Icons.security_rounded, 'مفاتيح API', 'تأمين الاتصال بالبوابات'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white30, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.sourceCodePro(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle) {
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
          Icon(icon, color: const Color(0xFF00E5FF), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(subtitle, style: GoogleFonts.cairo(fontSize: 9, color: Colors.white30)),
            ],
          )
        ],
      ),
    );
  }
}
