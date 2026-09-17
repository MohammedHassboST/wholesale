import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../state/app_state.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late final nameCtrl = TextEditingController(text: appState.currentName);
  late final emailCtrl = TextEditingController(text: appState.retailerEmail);
  late final ageCtrl = TextEditingController(text: appState.retailerAge?.toString() ?? '');
  late final addressCtrl = TextEditingController(text: appState.retailerAddress);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('بيانات الحساب', style: TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── عرض البيانات الحالية ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'البيانات الحالية',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inkSoft),
                      ),
                      const Divider(height: 20, color: AppColors.line),
                      _infoRow('اسم صاحب المحل', appState.currentName ?? '-'),
                      _infoRow('اسم المحل', appState.shopName ?? '-'),
                      _infoRow('رقم الهاتف', appState.currentPhone ?? '-'),
                      _infoRow('البريد الإلكتروني', appState.retailerEmail.isNotEmpty ? appState.retailerEmail : 'غير مسجل'),
                      _infoRow('العمر', appState.retailerAge != null ? '${appState.retailerAge} سنة' : 'غير مسجل'),
                      _infoRow('العنوان', appState.retailerAddress.isNotEmpty ? appState.retailerAddress : 'غير مسجل'),
                      _infoRow('تاريخ التسجيل', formatEgyptDate(appState.retailerRegistrationDate)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── تعديل البيانات ───
                const Text(
                  'تعديل البيانات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
                const SizedBox(height: 16),

                _buildField(controller: nameCtrl, label: 'اسم صاحب المحل', icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildField(controller: emailCtrl, label: 'البريد الإلكتروني (Gmail)', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildField(controller: ageCtrl, label: 'العمر', icon: Icons.cake_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildField(controller: addressCtrl, label: 'العنوان', icon: Icons.location_on_outlined),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (emailCtrl.text.isNotEmpty && !isValidGmail(emailCtrl.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('لازم يكون إيميل Gmail صحيح'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(12),
                          ),
                        );
                        return;
                      }
                      appState.updateRetailerInfo(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        age: int.tryParse(ageCtrl.text),
                        address: addressCtrl.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✓ تم حفظ البيانات'),
                          backgroundColor: AppColors.brand,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(12),
                        ),
                      );
                    },
                    child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.inkSoft.withValues(alpha: 0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          labelStyle: TextStyle(color: AppColors.inkSoft.withValues(alpha: 0.7), fontSize: 13),
        ),
      ),
    );
  }
  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد الخروج من الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout();
            },
            child: const Text('تأكيد الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}