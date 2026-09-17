import 'package:flutter/material.dart';
import '../../common/widgets/cart_drawer.dart';
import '../../state/app_state.dart';

class OffersFeedPage extends StatelessWidget {
  const OffersFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        // جلب العروض النشطة فقط التي لم تنفذ كميتها من جميع الموردين
        final activeOffers = appState.products.where((p) => p.isOfferActive).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('أقوى العروض', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CartDrawer(),
                    ),
                  ),
                  if (appState.cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text('${appState.cartCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              )
            ],
          ),
          body: activeOffers.isEmpty
              ? const Center(child: Text('لا توجد عروض نشطة حالياً'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: activeOffers.length,
            itemBuilder: (context, index) {
              final product = activeOffers[index];
              double pct = product.offerTotalQty > 0 ? (product.offerRemainingQty / product.offerTotalQty) : 0.0;
              if (pct > 1.0) pct = 1.0;
              if (pct < 0.0) pct = 0.0;

              Color progressColor = Colors.green;
              String stockStatusText = 'متبقي ${product.offerRemainingQty} من ${product.offerTotalQty} ${product.unit}';

              if (pct <= 0.10) {
                progressColor = Colors.red;
                stockStatusText = '⚠️ متبقي 10% فقط (${product.offerRemainingQty} ${product.unit})!';
              } else if (pct <= 0.30) {
                progressColor = Colors.orange;
                stockStatusText = '🔥 متبقي ${product.offerRemainingQty} ${product.unit}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                            child: Text('خصم!', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('المورد: ${product.vendorId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('${product.offerPrice} ج.م / ${product.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                          const SizedBox(width: 8),
                          Text('${product.price} ج.م', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // شريط التقدم للكمية المتبقية (Progress Bar)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey[200],
                          color: progressColor,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(stockStatusText, style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ElevatedButton.icon(
                            onPressed: () => appState.addToCart(product),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('أضف للسلة'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

      },
    );
  }
}