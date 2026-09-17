import 'product_entity.dart';

class OrderItemEntity {
  final ProductEntity product;
  final int qty;
  final double unitPrice;

  OrderItemEntity({
    required this.product,
    required this.qty,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * qty;

  Map<String, dynamic> toMap() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'unit': product.unit,
      'qty': qty,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory OrderItemEntity.fromMap(Map<String, dynamic> map, ProductEntity product) {
    return OrderItemEntity(
      product: product,
      qty: map['qty'] ?? 0,
      unitPrice: (map['unit_price'] ?? 0.0).toDouble(),
    );
  }
}

class OrderEntity {
  final String id;
  final String? parentOrderId;
  final String vendorId; // الطلب يتبع مورداً معيناً (طلب فرعي)
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String? clientAddress;
  final List<OrderItemEntity> items;
  final double total;
  final double savings;
  final DateTime createdAt;
  String status; // قيد المراجعة، مؤكد، جاري التجهيز، في الطريق، تم التسليم، مرفوض، ملغي
  final String paymentMethod; // COD

  OrderEntity({
    required this.id,
    this.parentOrderId,
    required this.vendorId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientAddress,
    required this.items,
    required this.total,
    required this.savings,
    required this.createdAt,
    required this.status,
    this.paymentMethod = 'COD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_order_id': parentOrderId,
      'vendor_id': vendorId,
      'client_id': clientId,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'total': total,
      'savings': savings,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
    };
  }

  factory OrderEntity.fromMap(Map<String, dynamic> map) {
    return OrderEntity(
      id: map['id'] ?? '',
      parentOrderId: map['parent_order_id'],
      vendorId: map['vendor_id'] ?? '',
      clientId: map['client_id'] ?? '',
      clientName: map['client_name'] ?? '',
      clientPhone: map['client_phone'] ?? '',
      clientAddress: map['client_address'],
      items: [], // Items are usually loaded separately or mapped from a nested response
      total: (map['total'] ?? 0.0).toDouble(),
      savings: (map['savings'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['payment_method'] ?? 'COD',
    );
  }
}