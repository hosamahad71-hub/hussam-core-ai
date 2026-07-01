import 'package:flutter/material.dart';
import '../../marketplace/bloc/marketplace_bloc.dart';

/// المطور: Hussam Core AI Engine
/// الوصف: لوحة تحكم التجار المتقدمة لإدارة الخدمات، المنتجات، ومتابعة الإحصائيات (Merchant UI)
class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({Key? key}) : super(key: key);

  @override
  _MerchantDashboardState createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  final MarketplaceBloc _bloc = MarketplaceBloc();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isAdding = false;

  // دالة فتح نافذة إضافة خدمة جديدة
  void _openAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181F), // لون النافذة داكن متناسق
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إضافة خدمة / منتج جديد',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // اسم المنتج
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('اسم الخدمة أو المنتج', Icons.shopping_bag_outlined),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                
                // السعر
                TextFormField(
                  controller: _priceController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('السعر ($)', Icons.attach_money_rounded),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'يرجى إدخال سعر صحيح' : null,
                ),
                const SizedBox(height: 16),
                
                // الوصف
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _buildInputDecoration('وصف تفصيلي للخدمة', Icons.description_outlined),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الوصف' : null,
                ),
                const SizedBox(height: 24),
                
                // زر الحفظ المربوط بالـ Bloc والسيرفر
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return ElevatedButton(
                      onPressed: _isAdding ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        
                        setModalState(() => _isAdding = true);
                        
                        final success = await _bloc.addNewItem(
                          name: _nameController.text.trim(),
                          price: double.parse(_priceController.text.trim()),
                          description: _descController.text.trim(),
                        );
                        
                        setModalState(() => _isAdding = false);
                        
                        if (success) {
                          _nameController.clear();
                          _priceController.clear();
                          _descController.clear();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إضافة المنتج بنجاح وتحديث المتجر', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.cyanAccent.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isAdding 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('نشر الخدمة فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    );
                  }
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181F),
        elevation: 0,
        title: const Text(
          'بوابة التاجر والعمليات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أهلاً بك يا شريكي، د. حسام',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const Text(
              'إليك أداء عملياتك ومنصتك الذكية اليوم',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 28),

            // لوحة إحصائيات النيون الفاخرة
            Row(
              children: [
                _buildStatCard('إجمالي المبيعات', '\$14,250', Colors.cyanAccent),
                const SizedBox(width: 14),
                _buildStatCard('الطلبات النشطة', '34 طلب', Colors.purpleAccent),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatCard('الخدمات المنشورة', '12 خدمة', Colors.greenAccent),
                const SizedBox(width: 14),
                _buildStatCard('تقييم المتجر', '4.9 ★', Colors.orangeAccent),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // زر إجراء سريع لإضافة منتج
            InkWell(
              onTap: _openAddItemSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade900.withOpacity(0.4), Colors.blueAccent.shade700.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_box_outlined, color: Colors.cyanAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'إضافة خدمة أو منتج جديد للسوق',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color neonColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: neonColor.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: neonColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF0D0E12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
    );
  }
}
