/// Wholesale quantity price tier: buying >= [minQty] units drops the
/// unit price to [price]. Stored as JSONB `price_tiers` on products.
class PriceTier {
  final int minQty;
  final double price;
  const PriceTier({required this.minQty, required this.price});

  Map<String, dynamic> toMap() => {'min_qty': minQty, 'price': price};

  factory PriceTier.fromMap(Map<String, dynamic> map) => PriceTier(
        minQty: ((map['min_qty'] ?? map['minQty'] ?? 1) as num).toInt(),
        price: ((map['price'] ?? 0) as num).toDouble(),
      );
}

class ProductEntity {
  final String id;
  final String vendorId;
  final String name;
  final String category;
  final double price; // السعر الأساسي أو سعر الجملة الأساسي
  final String unit; // كرتونة، قطعة، إلخ
  final int minOrderQty;
  final String? imagePath;
  final List<PriceTier> priceTiers;

  // الحد الأدنى لقيمة الشراء من هذا الصنف حصراً (0 = غير محدد)
  final double minOrderValue;

  // نظام العروض والتخفيضات والجدولة الزمنية
  final bool isOffer;
  final double offerPrice;
  final int offerTotalQty;
  int offerRemainingQty;
  final DateTime? offerStartDate;
  final DateTime? offerEndDate;

  // شروط التأهل للحصول على العرض:
  // 1. الحد الأدنى للكمية للحصول على سعر العرض (افتراضي: 1)
  final int offerMinQty;
  // 2. الحد الأدنى لقيمة الشراء من المتجر لتفعيل العرض (0 = غير مشروط)
  final double offerMinOrderValue;

  ProductEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    this.minOrderQty = 1,
    this.imagePath,
    this.priceTiers = const [],
    this.minOrderValue = 0.0,
    this.isOffer = false,
    this.offerPrice = 0.0,
    this.offerTotalQty = 0,
    this.offerRemainingQty = 0,
    this.offerStartDate,
    this.offerEndDate,
    this.offerMinQty = 1,
    this.offerMinOrderValue = 0.0,
  });

  // التحقق هل العرض نشط بناءً على تاريخ اليوم والكمية المتبقية
  bool get isOfferActive {
    if (!isOffer) return false;
    if (offerRemainingQty <= 0) return false;
    final now = DateTime.now();
    if (offerStartDate != null && now.isBefore(offerStartDate!)) return false;
    if (offerEndDate != null && now.isAfter(offerEndDate!)) return false;
    return true;
  }

  // عند نفاذ العرض أو انتهاء تاريخه، يعود المنتج لسعره الأصلي تلقائياً ويظل متاحاً
  double get currentPrice => isOfferActive ? offerPrice : price;

  // نسبة الكمية المتبقية في العرض
  double get offerRemainingPercentage {
    if (!isOffer || offerTotalQty <= 0) return 1.0;
    final pct = offerRemainingQty / offerTotalQty;
    if (pct < 0.0) return 0.0;
    if (pct > 1.0) return 1.0;
    return pct;
  }

  /// هل يستوفي هذا الطلب شروط الحصول على سعر العرض المخفض؟
  bool qualifiesForOffer(int qty, [double vendorSubtotal = 0.0]) {
    if (!isOfferActive) return false;
    if (offerMinQty > 1 && qty < offerMinQty) return false;
    if (offerMinOrderValue > 0 && vendorSubtotal > 0 && vendorSubtotal < offerMinOrderValue) {
      return false;
    }
    return true;
  }

  /// حساب سعر الوحدة الفعلي بناءً على الكمية وإجمالي طلب المورد (للتأهل للعرض والشرائح)
  double priceForQty(int qty, [double vendorSubtotal = 0.0]) {
    if (qualifiesForOffer(qty, vendorSubtotal)) return offerPrice;
    double best = price;
    for (final t in priceTiers) {
      if (qty >= t.minQty && t.price > 0 && t.price < best) best = t.price;
    }
    return best;
  }

  /// Lowest tier price for "as low as" display; null when no tiers.
  double? get lowestTierPrice {
    if (priceTiers.isEmpty) return null;
    double m = priceTiers.first.price;
    for (final t in priceTiers) {
      if (t.price > 0 && t.price < m) m = t.price;
    }
    return m;
  }

  bool get isSoldOut => false;

  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> rawTiers = priceTiers.map((t) => t.toMap()).toList();
    // نضمن قواعد الحدود الدنيا وشروط العرض ضمن JSONB price_tiers بدون الإخلال بمخطط الداتابيز
    if (minOrderValue > 0 || offerMinQty > 1 || offerMinOrderValue > 0) {
      rawTiers.add({
        '__meta_rules__': true,
        'min_order_value': minOrderValue,
        'offer_min_qty': offerMinQty,
        'offer_min_order_value': offerMinOrderValue,
      });
    }

    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'min_order_qty': minOrderQty,
      'image_path': imagePath,
      'price_tiers': rawTiers,
      'is_offer': isOffer,
      'offer_price': offerPrice,
      'offer_total_qty': offerTotalQty,
      'offer_remaining_qty': offerRemainingQty,
      'offer_start_date': offerStartDate?.toIso8601String(),
      'offer_end_date': offerEndDate?.toIso8601String(),
    };
  }

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    final rawTiersList = ((map['price_tiers'] ?? map['priceTiers']) as List?) ?? [];
    final List<PriceTier> parsedTiers = [];
    double parsedMinOrderVal = 0.0;
    int parsedOfferMinQty = 1;
    double parsedOfferMinOrderVal = 0.0;

    for (final item in rawTiersList) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        if (m['__meta_rules__'] == true || m['type'] == 'rules') {
          parsedMinOrderVal = (m['min_order_value'] as num?)?.toDouble() ?? 0.0;
          parsedOfferMinQty = (m['offer_min_qty'] as num?)?.toInt() ?? 1;
          parsedOfferMinOrderVal = (m['offer_min_order_value'] as num?)?.toDouble() ?? 0.0;
        } else if (m.containsKey('min_qty') && m.containsKey('price')) {
          parsedTiers.add(PriceTier.fromMap(m));
        }
      }
    }

    return ProductEntity(
      id: map['id'] ?? '',
      vendorId: map['vendor_id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      minOrderQty: map['min_order_qty'] ?? 1,
      imagePath: map['image_url'] ?? map['image_path'],
      priceTiers: parsedTiers,
      minOrderValue: parsedMinOrderVal,
      isOffer: map['is_offer'] ?? false,
      offerPrice: (map['offer_price'] ?? 0.0).toDouble(),
      offerTotalQty: map['offer_total_qty'] ?? 0,
      offerRemainingQty: map['offer_remaining_qty'] ?? 0,
      offerStartDate: map['offer_start_date'] != null
          ? DateTime.tryParse(map['offer_start_date'].toString())
          : null,
      offerEndDate: map['offer_end_date'] != null
          ? DateTime.tryParse(map['offer_end_date'].toString())
          : null,
      offerMinQty: parsedOfferMinQty,
      offerMinOrderValue: parsedOfferMinOrderVal,
    );
  }

  ProductEntity copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? category,
    double? price,
    String? unit,
    int? minOrderQty,
    String? imagePath,
    List<PriceTier>? priceTiers,
    double? minOrderValue,
    bool? isOffer,
    double? offerPrice,
    int? offerTotalQty,
    int? offerRemainingQty,
    DateTime? offerStartDate,
    DateTime? offerEndDate,
    int? offerMinQty,
    double? offerMinOrderValue,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      imagePath: imagePath ?? this.imagePath,
      priceTiers: priceTiers ?? this.priceTiers,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      isOffer: isOffer ?? this.isOffer,
      offerPrice: offerPrice ?? this.offerPrice,
      offerTotalQty: offerTotalQty ?? this.offerTotalQty,
      offerRemainingQty: offerRemainingQty ?? this.offerRemainingQty,
      offerStartDate: offerStartDate ?? this.offerStartDate,
      offerEndDate: offerEndDate ?? this.offerEndDate,
      offerMinQty: offerMinQty ?? this.offerMinQty,
      offerMinOrderValue: offerMinOrderValue ?? this.offerMinOrderValue,
    );
  }
}
