import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../core/l10n/app_strings.dart';

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
            title: Text(tr('قائمة طلباتي ومتابعة الحالات'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
                      Text(tr('لم تقم بإجراء أي طلبات حتى الآن'), style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold, fontSize: 14)),
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
                              Text(trArgs('طلب: {id}', {'id': o.id}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(o.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  orderStatusLabel(o.status),
                                  style: TextStyle(color: _getStatusColor(o.status), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(trArgs('المورد: {id}', {'id': o.vendorId}), style: const TextStyle(fontSize: 11, color: AppColors.brandDeep, fontWeight: FontWeight.bold)),
                          Text(trArgs('التاريخ: {d}', {'d': formatEgyptDateTime(o.createdAt)}), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                          const SizedBox(height: 10),

                          // صندوق تفاصيل الأصناف والأسعار
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.brandDeep),
                                    const SizedBox(width: 6),
                                    Text(
                                      trArgs('الأصناف ({n})', {'n': o.items.length}),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.brandDeep),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (o.items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      tr('جاري تحميل أصناف الطلب...'),
                                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
                                    ),
                                  )
                                else
                                  ...o.items.map((it) {
                                    final hasDiscount = it.unitPrice < it.product.price;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  it.product.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                const SizedBox(height: 3),
                                                Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  spacing: 8,
                                                  children: [
                                                    Text(
                                                      '${currency(it.unitPrice)} / ${unitLabel(it.product.unit)}',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                                                    ),
                                                    if (hasDiscount)
                                                      Text(
                                                        currency(it.product.price),
                                                        style: const TextStyle(
                                                          fontSize: 9.5,
                                                          color: AppColors.inkSoft,
                                                          decoration: TextDecoration.lineThrough,
                                                        ),
                                                      ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(4)),
                                                      child: Text(
                                                        '× ${it.qty}',
                                                        style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                currency(it.unitPrice * it.qty),
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink),
                                              ),
                                              if (hasDiscount)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.brandLight,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    tr('سعر عرض مخفض'),
                                                    style: const TextStyle(fontSize: 7.5, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trArgs('الإجمالي: {t}', {'t': currency(o.total)}), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.brandDeep)),
                                  if (o.savings > 0)
                                    Text(
                                      trArgs('إجمالي التوفير: {s}', {'s': currency(o.savings)}),
                                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  Text(trArgs('طريقة الدفع: {m}', {'m': o.paymentMethod}), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
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
                                        title: Text(tr('إلغاء الطلب'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        content: Text(tr('هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ (متاح أثناء حالة قيد الانتظار فقط)')),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('تراجع'))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              appState.cancelOrder(o.id);
                                            },
                                            child: Text(tr('تأكيد الإلغاء')),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 14),
                                  label: Text(tr('إلغاء الطلب'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                Text(
                                  o.status == 'ملغي' ? tr('تم إلغاء الطلب') : tr('الطلب قيد التنفيذ (لا يمكن الإلغاء)'),
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