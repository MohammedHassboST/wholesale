class ProductEntity {
  final String id;
  final String vendorId;
  final String name;
  final String category;
  final double price; // السعر الأساسي أو سعر الجملة الأساسي
  final String unit; // كرتونة، قطعة، إلخ
  final int minOrderQty;
  final String? imagePath;

  // نظام العروض والتخفيضات والجدولة الزمنية
  final bool isOffer;
  final double offerPrice;
  final int offerTotalQty;
  int offerRemainingQty;
  final DateTime? offerStartDate;
  final DateTime? offerEndDate;

  ProductEntity({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    this.minOrderQty = 1,
    this.imagePath,
    this.isOffer = false,
    this.offerPrice = 0.0,
    this.offerTotalQty = 0,
    this.offerRemainingQty = 0,
    this.offerStartDate,
    this.offerEndDate,
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

  bool get isSoldOut => false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'min_order_qty': minOrderQty,
      'image_path': imagePath,
      'is_offer': isOffer,
      'offer_price': offerPrice,
      'offer_total_qty': offerTotalQty,
      'offer_remaining_qty': offerRemainingQty,
      'offer_start_date': offerStartDate?.toIso8601String(),
      'offer_end_date': offerEndDate?.toIso8601String(),
    };
  }

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] ?? '',
      vendorId: map['vendor_id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      minOrderQty: map['min_order_qty'] ?? 1,
      imagePath: map['image_path'],
      isOffer: map['is_offer'] ?? false,
      offerPrice: (map['offer_price'] ?? 0.0).toDouble(),
      offerTotalQty: map['offer_total_qty'] ?? 0,
      offerRemainingQty: map['offer_remaining_qty'] ?? 0,
      offerStartDate: map['offer_start_date'] != null
          ? DateTime.parse(map['offer_start_date'])
          : null,
      offerEndDate: map['offer_end_date'] != null
          ? DateTime.parse(map['offer_end_date'])
          : null,
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
    bool? isOffer,
    double? offerPrice,
    int? offerTotalQty,
    int? offerRemainingQty,
    DateTime? offerStartDate,
    DateTime? offerEndDate,
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
      isOffer: isOffer ?? this.isOffer,
      offerPrice: offerPrice ?? this.offerPrice,
      offerTotalQty: offerTotalQty ?? this.offerTotalQty,
      offerRemainingQty: offerRemainingQty ?? this.offerRemainingQty,
      offerStartDate: offerStartDate ?? this.offerStartDate,
      offerEndDate: offerEndDate ?? this.offerEndDate,
    );
  }
}