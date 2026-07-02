import 'package:flutter/material.dart';
import '../services/ledger_service.dart';

class LedgerController extends ChangeNotifier {
  final LedgerService _ledgerService = LedgerService();

  // متغيرات إدارة حالة الواجهة
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double _currentBalance = 0.0;

  // Getters لتمكين الواجهات (UI) من القراءة الآمنة للبيانات
  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  double get currentBalance => _currentBalance;

  /// دالة جلب البيانات وتحديث الواجهة بالكامل
  Future<void> fetchUserLedger(int userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // إشعار الواجهات لبدء تأثير التحميل 

    final response = await _ledgerService.getLedger(userId);

    if (response['status'] == 'success') {
      _transactions = response['data']['data'] ?? [];
      
      if (_transactions.isNotEmpty) {
        _currentBalance = double.tryParse(_transactions.first['running_balance'].toString()) ?? 0.0;
      } else {
        _currentBalance = 0.0;
      }
    } else {
      _errorMessage = response['message'] ?? 'حدث خطأ غير متوقع أثناء تحديث البيانات.';
    }

    _isLoading = false;
    notifyListeners(); // تحديث الواجهات بالبيانات الجديدة
  }

  /// دالة تنفيذ عملية مالية جديدة (سحب / إيداع) من الواجهة
  Future<bool> executeTransaction({
    required int userId,
    required String type,
    required double amount,
    String? sector,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await _ledgerService.recordTransaction(
      userId: userId,
      type: type,
      amount: amount,
      sector: sector,
      description: description,
    );

    if (response['status'] == 'success') {
      await fetchUserLedger(userId); // تحديث الرصيد والقائمة تلقائياً بعد النجاح
      return true;
    } else {
      _errorMessage = response['message'] ?? 'فشل تنفيذ العملية المادية.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
