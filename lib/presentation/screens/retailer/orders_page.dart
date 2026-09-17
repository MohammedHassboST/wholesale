import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  Color _getStatusColor(String s) {
    switch (s) {
      case 'قيد المراجعة':
        return AppColors.amber;
      case 'مؤكد':
        return AppColors.brand;
      case 'جاري التجهيز':
        return Colors.blue;
      case 'في الطريق':
        return Colors.orange;
      case 'تم التسليم':
        return Colors.green;
      case 'ملغي':
      case 'مرفوض':
        return AppColors.danger;
      default:
        return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final myOrders = appState.orders.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('قائمة طلباتي ومتابعة الحالات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            backgroundColor: AppColors.brandDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: myOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.inkSoft.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('لم تقم بإجراء أي طلبات حتى الآن', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myOrders.length,
                  itemBuilder: (context, i) {
                    final o = myOrders[i];
                    final canCancel = o.status == 'قيد المراجعة';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(color: AppColors.ink.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('طلب: ${o.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(o.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  o.status,
                                  style: TextStyle(color: _getStatusColor(o.status), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('المورد: ${o.vendorId}', style: const TextStyle(fontSize: 11, color: AppColors.brandDeep, fontWeight: FontWeight.bold)),
                          Text('التاريخ: ${formatEgyptDateTime(o.createdAt)}', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                          const Divider(height: 14),
                          ...o.items.map((it) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• ${it.product.name} (${it.product.unit}) × ${it.qty}', style: const TextStyle(fontSize: 12)),
                                    Text(currency(it.unitPrice * it.qty), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الإجمالي: ${currency(o.total)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.brandDeep)),
                                  Text('طريقة الدفع: ${o.paymentMethod}', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                                ],
                              ),
                              if (canCancel)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                                        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ (متاح أثناء حالة قيد الانتظار فقط)'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              appState.cancelOrder(o.id);
                                            },
                                            child: const Text('تأكيد الإلغاء'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 14),
                                  label: const Text('إلغاء الطلب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                Text(
                                  o.status == 'ملغي' ? 'تم إلغاء الطلب' : 'الطلب قيد التنفيذ (لا يمكن الإلغاء)',
                                  style: TextStyle(fontSize: 10, color: AppColors.inkSoft.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                                ),
                            ],
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
}