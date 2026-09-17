import 'package:flutter/material.dart';
import 'dart:io';
import '../../../domain/entities/product_entity.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../core/l10n/app_strings.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final p = appState.products.firstWhere((item) => item.id == product.id, orElse: () => product);
        final isOfferStillValid = p.isOfferActive;
        final displayPrice = p.currentPrice;
        final cartQty = appState.qtyInCart(p.id);

        double progressVal = p.offerRemainingPercentage;
        Color progressColor = AppColors.brand;
        String remainingText = trArgs('متبقي {r} من {t}', {'r': p.offerRemainingQty, 't': p.offerTotalQty});

        if (progressVal <= 0.10) {
          progressColor = AppColors.danger;
          remainingText = trArgs('⚠️ متبقي 10% فقط ({r} {u})!', {'r': p.offerRemainingQty, 'u': unitLabel(p.unit)});
        } else if (progressVal <= 0.30) {
          progressColor = AppColors.amber;
          remainingText = trArgs('🔥 متبقي {r} {u}', {'r': p.offerRemainingQty, 'u': unitLabel(p.unit)});
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الصنف أو الأيقونة
              Stack(
                children: [
                  Container(
                    height: 95,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: (p.imagePath != null && p.imagePath!.startsWith('http'))
                          ? Image.network(p.imagePath!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2, color: AppColors.brand, size: 36))
                          : (p.imagePath != null && File(p.imagePath!).existsSync())
                              ? Image.file(File(p.imagePath!), fit: BoxFit.cover)
                              : Icon(Icons.inventory_2_outlined, size: 38, color: isOfferStillValid ? AppColors.amber : AppColors.brand),
                    ),
                  ),
                  if (isOfferStillValid)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                        child: Text(tr('عرض خاص 🔥'), style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),

              // التفاصيل والأسعار
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(trArgs('المورد: {id}', {'id': p.vendorId}), style: const TextStyle(fontSize: 10, color: AppColors.brandDeep, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                currency(displayPrice),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.brandDeep),
                              ),
                              if (isOfferStillValid && p.price > displayPrice) ...[
                                const SizedBox(width: 4),
                                Text(
                                  currency(p.price),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.inkSoft,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(trArgs('الوحدة: {u} (الحد الأدنى: {m})', {'u': unitLabel(p.unit), 'm': p.minOrderQty}), style: const TextStyle(fontSize: 9, color: AppColors.inkSoft)),
                          if (!isOfferStillValid && p.lowestTierPrice != null && p.lowestTierPrice! < p.price)
                            Text(
                              trArgs('💰 سعر متدرج حتى {price} للكميات', {'price': currency(p.lowestTierPrice!)}),
                              style: const TextStyle(fontSize: 9, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                            ),

                          // شريط التقدم للكمية المتبقية للعرض
                          if (isOfferStillValid) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                color: progressColor,
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              remainingText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: progressColor),
                            ),
                          ] else if (p.isOffer && p.offerRemainingQty <= 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              tr('انتهى العرض (متاح للشراء بالسعر الأصلي)'),
                              style: TextStyle(fontSize: 9, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),

                      // زر الإضافة للسلة
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cartQty > 0 ? AppColors.brandDeep : AppColors.ink,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => appState.addToCart(p),
                          child: Text(
                            cartQty > 0 ? trArgs('في السلة ({q})', {'q': cartQty}) : tr('أضف للسلة'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}