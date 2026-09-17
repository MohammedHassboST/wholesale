import 'package:flutter/material.dart';
import '../../../domain/entities/product_entity.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final imageCtrl = TextEditingController();
  final customUnitCtrl = TextEditingController();

  late final List<String> validCategories = appState.categories.where((c) => c != 'الكل').toList();
  late String selectedCategory = validCategories.isNotEmpty ? validCategories.first : 'مواد غذائية';

  String selectedUnit = kWholesaleUnits.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('إضافة صنف جديد للمخزون')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الصنف')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: validCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
            const SizedBox(height: 14),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر الأساسي / سعر الجملة')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: kWholesaleUnits.contains(selectedUnit) ? selectedUnit : 'أخرى (تحديد يدوي)',
              items: kWholesaleUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => selectedUnit = v!),
              decoration: const InputDecoration(labelText: 'نظام وحدة بيع الجملة'),
            ),
            if (selectedUnit == 'أخرى (تحديد يدوي)') ...[
              const SizedBox(height: 10),
              TextField(
                controller: customUnitCtrl,
                decoration: const InputDecoration(labelText: 'اكتب اسم الوحدة المخصصة (مثلاً: كرتونة 24 قطعة)'),
              ),
            ],
            const SizedBox(height: 14),
            TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)')),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                final finalUnit = selectedUnit == 'أخرى (تحديد يدوي)'
                    ? (customUnitCtrl.text.trim().isEmpty ? 'وحدة' : customUnitCtrl.text.trim())
                    : selectedUnit;

                final newProduct = ProductEntity(
                  id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                  vendorId: appState.currentUser?.id ?? 'vendor_1',
                  name: nameCtrl.text.trim(),
                  category: selectedCategory,
                  price: double.parse(priceCtrl.text),
                  unit: finalUnit,
                  imagePath: imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
                );
                appState.addProduct(newProduct);
                Navigator.pop(context);
              },
              child: const Text('حفظ وإضافة الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}