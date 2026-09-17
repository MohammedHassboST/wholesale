import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  String? selectedProductId;
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final available = appState.products.where((p) => !p.isOffer).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء عرض')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر الصنف', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedProductId,
              items: available
                  .map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => selectedProductId = v),
              decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: AppColors.card),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر العرض', border: OutlineInputBorder(), filled: true, fillColor: AppColors.card),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية المخصصة للعرض', border: OutlineInputBorder(), filled: true, fillColor: AppColors.card),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (selectedProductId == null || priceCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;
                  appState.createOffer(
                    selectedProductId!,
                    double.parse(priceCtrl.text),
                    int.parse(qtyCtrl.text),
                  );
                  Navigator.pop(context);
                },
                child: const Text('إنشاء العرض', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}