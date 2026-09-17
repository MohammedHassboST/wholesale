import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final groupedCarts = appState.cartGroupedByVendor;
        final isValid = appState.isCartValidForCheckout;
        final totalSavings = appState.cartTotalSavings;

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // رأس السلة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppColors.brandDeep,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text('سلة المشتريات المجمعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        if (groupedCarts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('${groupedCarts.length} موردين', style: const TextStyle(color: AppColors.brandDeep, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // محتوى السلة مقسماً تلقائياً حسب كل مورد
              Expanded(
                child: appState.cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_shopping_cart_outlined, size: 60, color: AppColors.inkSoft.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text('سلة الشراء فارغة حالياً', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFF92400E), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'الطلب سينقسم تلقائياً لطلب فرعي لكل مورد للتجهيز والشحن المستقل. الدفع كاش عند الاستلام (COD).',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...groupedCarts.entries.map((entry) {
                            final vendorId = entry.key;
                            final items = entry.value;
                            final subtotal = appState.vendorSubtotal(vendorId);
                            final meetsMin = subtotal >= appState.minOrderValuePerVendor;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: meetsMin ? AppColors.line : AppColors.danger.withValues(alpha: 0.5),
                                  width: meetsMin ? 1 : 1.5,
                                ),
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
                                      Row(
                                        children: [
                                          const Icon(Icons.store, size: 18, color: AppColors.brand),
                                          const SizedBox(width: 6),
                                          Text('طلب المورد: $vendorId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandDeep)),
                                        ],
                                      ),
                                      Text(
                                        'الحد الأدنى: ${currency(appState.minOrderValuePerVendor)}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 14),
                                  ...items.map((cartItem) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cartItem.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                Text(
                                                  '${currency(cartItem.unitPrice)} / ${cartItem.product.unit}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                                                onPressed: () => appState.changeQty(cartItem.product.id, cartItem.qty - cartItem.product.minOrderQty),
                                              ),
                                              Text('${cartItem.qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.brand),
                                                onPressed: () => appState.changeQty(cartItem.product.id, cartItem.qty + cartItem.product.minOrderQty),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('مجموع طلب المورد: ${currency(subtotal)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                      if (!meetsMin)
                                        Text(
                                          'يتبقى ${currency(appState.minOrderValuePerVendor - subtotal)} للحد الأدنى!',
                                          style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                                        )
                                      else
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                                            SizedBox(width: 4),
                                            Text('استوفى الحد الأدنى', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
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

              // ملخص السلة وتأكيد الطلب
              if (appState.cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (totalSavings > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي الخصومات والتوفير:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('- ${currency(totalSavings)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي العام لكافة الطلبات:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          Text(currency(appState.cartTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.brandDeep)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'طريقة الدفع للمرحلة الأولى: كاش عند الاستلام (COD) لكافة الطلبات الفرعية',
                        style: TextStyle(fontSize: 10, color: AppColors.inkSoft, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isValid ? AppColors.brand : AppColors.inkSoft,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isValid && !appState.isCheckingOut
                              ? () async {
                                  final navigator = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await appState.checkout();
                                  if (ok) {
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('تم تأكيد الطلب بنجاح وتوزيعه على الموردين بشكل فوري!'),
                                        backgroundColor: AppColors.brand,
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('حدث خطأ أو نفذت بعض الكميات المتاحة!'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: appState.isCheckingOut
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isValid ? 'تأكيد وتقسيم الطلب (COD)' : 'لم تكتمل الحدود الدنيا للموردين',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}