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
}