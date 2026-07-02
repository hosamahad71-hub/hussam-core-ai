import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/ledger_controller.dart';

class LedgerView extends StatefulWidget {
  final int userId;

  const LedgerView({super.key, required this.userId});

  @override
  State<LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<LedgerView> {
  final LedgerController _controller = LedgerController();

  @override
  void initState() {
    super.initState();
    // استدعاء البيانات لحظياً عند فتح الشاشة
    _controller.fetchUserLedger(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090a0f), // خلفية داكنة فاخرة للمصفوفة
      app_bar: AppBar(
        title: const Text('MATRIX LEDGER', style: TextStyle(fontFamily: 'Orbitron', letterSpacing: 2, color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          if (_controller.errorMessage.isNotEmpty) {
            return Center(child: Text(_controller.errorMessage, style: const TextStyle(color: Colors.redAccent)));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. كارت الرصيد الكلي بتصميم Glassmorphic ومؤثرات توهج نيوني
                _buildBalanceCard(_controller.currentBalance),
                const SizedBox(height: 24),
                
                const Text(
                  'العمليات المادية اللحظية',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),

                // 2. قائمة كشف الحساب اللحظي المنسابة من السيرفر
                Expanded(
                  child: _controller.transactions.isEmpty
                      ? const Center(child: Text('لا توجد عمليات مسجلة في المصفوفة حتى الآن', style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          itemCount: _controller.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = _controller.transactions[index];
                            return _buildTransactionRow(tx);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ويدجت الكارت الزجاجي الفاخر لعرض الرصيد
  Widget _buildBalanceCard(double balance) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              const Text('OPERATIONAL BALANCE', style: TextStyle(color: Colors.white38, fontFamily: 'Orbitron', fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                '${balance.toStringAsFixed(2)} \$',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت السطر المالي المخصص لكل عملية (سحب / إيداع)
  Widget _buildTransactionRow(dynamic tx) {
    final bool isCredit = tx['type'] == 'credit';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // القيمة المالية وحالتها نيونية
          Text(
            '${isCredit ? "+" : "-"}${tx['amount']} \$',
            style: TextStyle(
              color: isCredit ? Colors.emeraldAccent : Colors.roseAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          // تفاصيل العملية المكتوبة بالباك-إند
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx['description'] ?? 'عملية مصفوفة غير معرفة', style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                tx['sector'] ?? 'General',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
