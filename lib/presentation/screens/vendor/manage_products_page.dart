import 'package:flutter/material.dart';
import '../../../domain/entities/product_entity.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../admin/add_product_page.dart';

class ManageProductsPage extends StatelessWidget {
  const ManageProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('إدارة الأصناف', style: TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
          ),
          body: appState.products.isEmpty
              ? Center(
            child: Text(
              'مفيش أصناف',
              style: TextStyle(fontSize: 15, color: AppColors.inkSoft.withValues(alpha: 0.5)),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appState.products.length,
            itemBuilder: (context, i) {
              final p = appState.products[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.ink.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            '${currency(p.price)} / ${p.unit}',
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                          if (p.isOffer)
                            Text(
                              'عرض: ${currency(p.offerPrice)} · متبقي ${p.offerRemainingQty}',
                              style: const TextStyle(fontSize: 12, color: AppColors.amber),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
                      onPressed: () => _showEditProductDialog(context, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('حذف الصنف'),
                            content: Text('متأكد إنك عاوز تحذف "${p.name}"؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () {
                                  appState.deleteProduct(p.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage())),
            backgroundColor: AppColors.brand,
            icon: const Icon(Icons.add),
            label: const Text('صنف جديد'),
          ),
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, ProductEntity p) {
    final nameCtrl = TextEditingController(text: p.name);
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(0));
    final customUnitCtrl = TextEditingController(text: kWholesaleUnits.contains(p.unit) ? '' : p.unit);
    final imageCtrl = TextEditingController(text: p.imagePath ?? '');
    String currentCat = p.category;
    String selectedUnit = kWholesaleUnits.contains(p.unit) ? p.unit : 'أخرى (تحديد يدوي)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل الصنف', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الصنف'),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: appState.categories.contains(currentCat) ? currentCat : appState.categories.first,
                        items: appState.categories.where((c) => c != 'الكل').map((c) {
                          return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (v) => setDialogState(() => currentCat = v!),
                        decoration: const InputDecoration(labelText: 'التصنيف'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر الأساسي'),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  items: kWholesaleUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setDialogState(() => selectedUnit = v!),
                  decoration: const InputDecoration(labelText: 'وحدة بيع الجملة'),
                ),
                if (selectedUnit == 'أخرى (تحديد يدوي)') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customUnitCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الوحدة المخصصة (مثلاً: طرد 12 قطعة)'),
                    textAlign: TextAlign.right,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)'),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                final finalUnit = selectedUnit == 'أخرى (تحديد يدوي)'
                    ? (customUnitCtrl.text.trim().isEmpty ? p.unit : customUnitCtrl.text.trim())
                    : selectedUnit;

                final updated = ProductEntity(
                  id: p.id,
                  vendorId: p.vendorId,
                  name: nameCtrl.text.trim(),
                  category: currentCat,
                  price: double.tryParse(priceCtrl.text) ?? p.price,
                  unit: finalUnit,
                  minOrderQty: p.minOrderQty,
                  isOffer: p.isOffer,
                  offerPrice: p.offerPrice,
                  offerTotalQty: p.offerTotalQty,
                  offerRemainingQty: p.offerRemainingQty,
                  imagePath: imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
                );

                appState.updateProduct(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

}