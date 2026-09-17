import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import 'create_offer_page.dart';

class ManageOffersPage extends StatelessWidget {
  const ManageOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final offers = appState.products.where((p) => p.isOffer).toList();

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('إدارة العروض', style: TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
          ),
          body: offers.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer_outlined, size: 48, color: AppColors.inkSoft.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'مفيش عروض حالياً',
                  style: TextStyle(fontSize: 15, color: AppColors.inkSoft.withValues(alpha: 0.5)),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final p = offers[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.ink.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amberSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currency(p.offerPrice),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الكمية: ${p.offerRemainingQty} من ${p.offerTotalQty}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brand,
                              side: const BorderSide(color: AppColors.brand),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showEditOfferDialog(context, p),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('تعديل'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('حذف العرض'),
                                  content: Text('متأكد إنك عاوز تحذف العرض من "${p.name}"؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        appState.deleteOffer(p.id);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('حذف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOfferPage())),
            backgroundColor: AppColors.brand,
            icon: const Icon(Icons.add),
            label: const Text('عرض جديد'),
          ),
        );
      },
    );
  }

  void _showEditOfferDialog(BuildContext context, dynamic p) {
    final priceCtrl = TextEditingController(text: p.offerPrice.toStringAsFixed(0));
    final qtyCtrl = TextEditingController(text: p.offerTotalQty.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل العرض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر العرض'),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية المخصصة'),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text) ?? p.offerPrice;
              final newQty = int.tryParse(qtyCtrl.text) ?? p.offerTotalQty;
              appState.createOffer(p.id, newPrice, newQty);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}