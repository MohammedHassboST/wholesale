import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  late final nameCtrl = TextEditingController(text: appState.currentUser?.name);
  late final emailCtrl = TextEditingController(text: appState.adminEmail);
  late final phoneCtrl = TextEditingController(text: appState.currentUser?.phone);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('بيانات الحساب', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 14),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                appState.updateAdminInfo(name: nameCtrl.text.trim(), email: emailCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم حفظ البيانات')));
              },
              child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}