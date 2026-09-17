import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.vendorId,
    required super.name,
    required super.category,
    required super.price,
    required super.unit,
    super.minOrderQty,
    super.isOffer,
    super.offerPrice,
    super.offerTotalQty,
    super.offerRemainingQty,
    super.offerStartDate,
    super.offerEndDate,
    super.imagePath,
    super.priceTiers,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      vendorId: (map['vendor_id'] ?? map['vendorId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      category: (map['category'] ?? 'الكل').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] ?? 'كرتونة').toString(),
      minOrderQty: (map['min_order_qty'] ?? map['minOrderQty'] as num?)?.toInt() ?? 1,
      isOffer: map['is_offer'] ?? map['isOffer'] ?? false,
      offerPrice: (map['offer_price'] ?? map['offerPrice'] as num?)?.toDouble() ?? 0.0,
      offerTotalQty: (map['offer_total_qty'] ?? map['offerTotalQty'] as num?)?.toInt() ?? 0,
      offerRemainingQty: (map['offer_remaining_qty'] ?? map['offerRemainingQty'] as num?)?.toInt() ?? 0,
      offerStartDate: map['offer_start_date'] != null
          ? DateTime.tryParse(map['offer_start_date'].toString())
          : (map['offerStartDate'] != null ? DateTime.tryParse(map['offerStartDate'].toString()) : null),
      offerEndDate: map['offer_end_date'] != null
          ? DateTime.tryParse(map['offer_end_date'].toString())
          : (map['offerEndDate'] != null ? DateTime.tryParse(map['offerEndDate'].toString()) : null),
      imagePath: (map['image_url'] ?? map['image_path'] ?? map['imagePath'])?.toString(),
      priceTiers: ((map['price_tiers'] ?? map['priceTiers']) as List?)
              ?.map((e) => PriceTier.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }

  factory ProductModel.fromEntity(ProductEntity p) {
    return ProductModel(
      id: p.id,
      vendorId: p.vendorId,
      name: p.name,
      category: p.category,
      price: p.price,
      unit: p.unit,
      minOrderQty: p.minOrderQty,
      isOffer: p.isOffer,
      offerPrice: p.offerPrice,
      offerTotalQty: p.offerTotalQty,
      offerRemainingQty: p.offerRemainingQty,
      offerStartDate: p.offerStartDate,
      offerEndDate: p.offerEndDate,
      imagePath: p.imagePath,
      priceTiers: p.priceTiers,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'min_order_qty': minOrderQty,
      'is_offer': isOffer,
      'offer_price': offerPrice,
      'offer_total_qty': offerTotalQty,
      'offer_remaining_qty': offerRemainingQty,
      'offer_start_date': offerStartDate?.toIso8601String(),
      'offer_end_date': offerEndDate?.toIso8601String(),
      'image_url': imagePath,
      'price_tiers': priceTiers.map((t) => t.toMap()).toList(),
    };
  }
}