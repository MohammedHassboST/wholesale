import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('إدارة المخزون')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appState.products.length,
            itemBuilder: (context, i) {
              final p = appState.products[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${currency(p.price)} / ${p.unit}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          if (p.isOffer)
                            Text('عرض: ${currency(p.offerPrice)} · متبقي ${p.offerRemainingQty}', style: const TextStyle(fontSize: 12, color: AppColors.amber)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showStockDialog(context, p),
                      child: const Text('تعديل مخزون'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showStockDialog(BuildContext context, dynamic p) {
    final ctrl = TextEditingController(text: p.isOffer ? p.offerRemainingQty.toString() : '0');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل المخزون المتاح'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الكمية المتاحة للعرض'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              appState.updateProductStock(p.id, int.tryParse(ctrl.text) ?? 0);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}