import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_hub.dart';

class SovereignLoginPage extends StatefulWidget {
  const SovereignLoginPage({super.key});

  @override
  State<SovereignLoginPage> createState() => _SovereignLoginPageState();
}

class _SovereignLoginPageState extends State<SovereignLoginPage> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleAuthAction() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isLoading = false);

    if (!_isOtpSent) {
      if (_phoneController.text.isNotEmpty) {
        setState(() => _isOtpSent = true);
      }
    } else {
      if (_otpController.text.length >= 4) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AppNavigationHub()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF161B22),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3 + (_glowController.value * 0.4)),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.1 * _glowController.value),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF00E5FF)),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'GATEWAY ACCESS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'بوابة التحقق الرقمي السيادي والـ OTP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
                ),
                const SizedBox(height: 40),
                if (!_isOtpSent) ...[
                  Text(
                    'رقم الهاتف الموحد',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.sourceCodePro(color: Colors.greenAccent),
                    decoration: InputDecoration(
                      hintText: '+967 7XXXXXXXX',
                      hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 14),
                      fillColor: const Color(0xFF161B22),
                      filled: true,
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.white30),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'رمز التحقق السري (OTP)',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sourceCodePro(color: Colors.amberAccent, fontSize: 22, letterSpacing: 10),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: GoogleFonts.sourceCodePro(color: Colors.white10, fontSize: 22, letterSpacing: 10),
                      fillColor: const Color(0xFF161B22),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.amberAccent, width: 1),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuthAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpSent ? const Color(0xFF7000FF) : const Color(0xFF00E5FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isOtpSent ? 'تأكيد الدخول الآمن' : 'إرسال مفتاح التحقق',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
                if (_isOtpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isOtpSent = false),
                    child: Text(
                      'تعديل رقم الهاتف',
                      style: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
