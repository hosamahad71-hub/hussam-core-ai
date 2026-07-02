import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogisticsEnterpriseDashboard extends StatefulWidget {
  const LogisticsEnterpriseDashboard({super.key});

  @override
  State<LogisticsEnterpriseDashboard> createState() => _LogisticsEnterpriseDashboardState();
}

class _LogisticsEnterpriseDashboardState extends State<LogisticsEnterpriseDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

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
                        'LOGISTICS HUB',
                        style: GoogleFonts.orbitron(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إدارة قنوات الإمداد والربط السيادي',
                        style: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                  RotationTransition(
                    turns: _radarController,
                    child: const Icon(Icons.track_changes_rounded, color: Colors.greenAccent),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLogisticsMetric('الشحنات الجارية', '142', Colors.amberAccent),
                    _buildLogisticsMetric('عقد الربط النشطة', '8', const Color(0xFF00E5FF)),
                    _buildLogisticsMetric('المحافظ المؤمّنة', '100%', Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'حالة مسارات النقل والربط الحي',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _buildRouteStatusCard('خط ربط: صنعاء - عدن', 'مستقر وجاري النقل', Icons.check_circle_rounded, Colors.greenAccent),
              const SizedBox(height: 12),
              _buildRouteStatusCard('شريان الإمداد: تعز - المقاطرة', 'تحميل الشحنات الحالية', Icons.radio_button_checked_rounded, Colors.amberAccent),
              const SizedBox(height: 12),
              _buildRouteStatusCard('الخط الساحلي: حضرموت - الحديدة', 'مؤمن بالكامل', Icons.shield_rounded, const Color(0xFF00E5FF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.sourceCodePro(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.cairo(color: Colors.white30, fontSize: 11)),
      ],
    );
  }

  Widget _buildRouteStatusCard(String route, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(status, style: GoogleFonts.cairo(fontSize: 11, color: Colors.white30)),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
        ],
      ),
    );
  }
}
