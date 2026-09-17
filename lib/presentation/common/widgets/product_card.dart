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

        // الكمية الفعلية المتبقية بعد احتساب ما أضيف إلى السلة
        final availableAfterCart = isOfferStillValid
            ? (p.offerRemainingQty - cartQty).clamp(0, p.offerTotalQty)
            : p.offerRemainingQty;
        final progressVal = (isOfferStillValid && p.offerTotalQty > 0)
            ? (availableAfterCart / p.offerTotalQty).clamp(0.0, 1.0)
            : 1.0;

        Color progressColor = AppColors.brand;
        String remainingText = trArgs('متبقي {r} من {t}', {'r': availableAfterCart, 't': p.offerTotalQty});

        if (availableAfterCart <= 0) {
          progressColor = AppColors.danger;
          remainingText = cartQty > 0
              ? tr('تم حجز كل الكمية المتاحة بالسلة!')
              : tr('نفذت الكمية');
        } else if (progressVal <= 0.10) {
          progressColor = AppColors.danger;
          remainingText = trArgs('⚠️ متبقي 10% فقط ({r} {u})!', {'r': availableAfterCart, 'u': unitLabel(p.unit)});
        } else if (progressVal <= 0.30) {
          progressColor = AppColors.amber;
          remainingText = trArgs('🔥 متبقي {r} {u}', {'r': availableAfterCart, 'u': unitLabel(p.unit)});
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
                        child: Text(tr('عرض خاص 🔥'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else if (p.isOffer && (p.offerRemainingQty <= 0 || !p.isOfferActive))
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.inkSoft, borderRadius: BorderRadius.circular(6)),
                        child: Text(tr('انتهى العرض ⚠️'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                          if (p.minOrderValue > 0)
                            Text(
                              trArgs('الحد الأدنى للشراء: {val}', {'val': currency(p.minOrderValue)}),
                              style: const TextStyle(fontSize: 8.5, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                            ),
                          if (isOfferStillValid && (p.offerMinQty > 1 || p.offerMinOrderValue > 0)) ...[
                            const SizedBox(height: 2),
                            if (p.offerMinQty > 1 && p.offerMinOrderValue > 0)
                              Text(
                                trArgs('شرط العرض: {q} {u} + طلب {v}', {'q': p.offerMinQty, 'u': unitLabel(p.unit), 'v': currency(p.offerMinOrderValue)}),
                                style: const TextStyle(fontSize: 8, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                              )
                            else if (p.offerMinQty > 1)
                              Text(
                                trArgs('شرط العرض: شراء {q} {u} فأكثر', {'q': p.offerMinQty, 'u': unitLabel(p.unit)}),
                                style: const TextStyle(fontSize: 8, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                              )
                            else if (p.offerMinOrderValue > 0)
                              Text(
                                trArgs('شرط العرض: طلب بقيمة {v} من المورد', {'v': currency(p.offerMinOrderValue)}),
                                style: const TextStyle(fontSize: 8, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                              ),
                            if (cartQty > 0) ...[
                              const SizedBox(height: 2),
                              Builder(builder: (context) {
                                final vSub = appState.vendorSubtotal(p.vendorId);
                                final isQualified = p.qualifiesForOffer(cartQty, vSub);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isQualified ? Colors.green.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isQualified ? Colors.green.shade300 : Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    isQualified ? tr('مؤهل لسعر العرض 🎉') : tr('غير مؤهل لسعر العرض (شروط غير مكتملة)'),
                                    style: TextStyle(fontSize: 7.5, color: isQualified ? Colors.green.shade800 : Colors.amber.shade900, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }),
                            ],
                          ],
                          if (!isOfferStillValid && p.lowestTierPrice != null && p.lowestTierPrice! < p.price)
                            Text(
                              trArgs('💰 سعر متدرج حتى {price} للكميات', {'price': currency(p.lowestTierPrice!)}),
                              style: const TextStyle(fontSize: 9, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                            ),

                          // شريط التقدم للكمية المتبقية للعرض يتناقص ديناميكياً مع الإضافة للسلة
                          if (isOfferStillValid) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(begin: progressVal, end: progressVal),
                                builder: (context, val, _) => LinearProgressIndicator(
                                  value: val,
                                  color: progressColor,
                                  backgroundColor: Colors.grey.shade200,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              remainingText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: progressColor),
                            ),
                          ] else if (p.isOffer && (p.offerRemainingQty <= 0 || !p.isOfferActive)) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blueGrey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 11, color: AppColors.brand),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      tr('انتهى العرض — متاح بالسعر الأصلي'),
                                      style: const TextStyle(fontSize: 8.5, color: AppColors.brandDeep, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // زر الإضافة للسلة مع مراعاة الحد الأقصى للمخزون
                      Builder(builder: (context) {
                        final bool canAddMore = !isOfferStillValid || (availableAfterCart >= p.minOrderQty);
                        return SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !canAddMore && cartQty > 0
                                  ? AppColors.inkSoft
                                  : (cartQty > 0 ? AppColors.brandDeep : AppColors.ink),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: canAddMore ? () => appState.addToCart(p) : null,
                            child: Text(
                              !canAddMore && cartQty > 0
                                  ? trArgs('في السلة ({q}) - الحد الأقصى', {'q': cartQty})
                                  : (cartQty > 0 ? trArgs('في السلة ({q})', {'q': cartQty}) : tr('أضف للسلة')),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
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