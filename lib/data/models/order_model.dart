import '../../domain/entities/order_entity.dart';
import 'product_model.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    required super.id,
    super.parentOrderId,
    required super.vendorId,
    required super.clientId,
    required super.clientName,
    required super.clientPhone,
    super.clientAddress,
    required super.items,
    required super.total,
    required super.savings,
    required super.createdAt,
    required super.status,
    super.paymentMethod = 'COD',
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final itemsList = ((map['items'] ?? map['order_items']) as List? ?? []).map((e) {
      final pMap = e['product'] ?? e;
      final pId = (pMap['id'] ?? pMap['product_id'] ?? '').toString();
      final pName = (pMap['name'] ?? pMap['product_name'] ?? '').toString();
      final pCat = (pMap['category'] ?? pMap['product_category'] ?? 'الكل').toString();
      final pUnit = (pMap['unit'] ?? pMap['product_unit'] ?? 'كرتونة').toString();
      final uPrice = (e['unit_price'] ?? e['unitPrice'] ?? pMap['price'] as num?)?.toDouble() ?? 0.0;
      final q = (e['qty'] as num?)?.toInt() ?? 1;

      return OrderItemEntity(
        product: ProductModel.fromMap(
          pMap is Map<String, dynamic> 
            ? {...pMap, 'name': pName, 'category': pCat, 'unit': pUnit} 
            : {'name': pName, 'category': pCat, 'unit': pUnit}, 
          pId
        ),
        qty: q,
        unitPrice: uPrice,
      );
    }).toList();

    return OrderModel(
      id: docId,
      parentOrderId: map['parent_order_id'] ?? map['parentOrderId'],
      vendorId: (map['vendor_id'] ?? map['vendorId'] ?? '').toString(),
      clientId: (map['client_id'] ?? map['clientId'] ?? '').toString(),
      clientName: (map['client_name'] ?? map['clientName'] ?? '').toString(),
      clientPhone: (map['client_phone'] ?? map['clientPhone'] ?? '').toString(),
      clientAddress: (map['client_address'] ?? map['clientAddress'])?.toString(),
      items: itemsList,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      savings: (map['savings'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now()),
      status: (map['status'] ?? 'قيد المراجعة').toString(),
      paymentMethod: (map['payment_method'] ?? map['paymentMethod'] ?? 'COD').toString(),
    );
  }

  factory OrderModel.fromEntity(OrderEntity o) {
    return OrderModel(
      id: o.id,
      parentOrderId: o.parentOrderId,
      vendorId: o.vendorId,
      clientId: o.clientId,
      clientName: o.clientName,
      clientPhone: o.clientPhone,
      clientAddress: o.clientAddress,
      items: o.items,
      total: o.total,
      savings: o.savings,
      createdAt: o.createdAt,
      status: o.status,
      paymentMethod: o.paymentMethod,
    );
  }

  @override
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
      'items': items.map((e) => {
        'product_id': e.product.id,
        'qty': e.qty,
        'unit_price': e.unitPrice,
      }).toList(),
    };
  }
}