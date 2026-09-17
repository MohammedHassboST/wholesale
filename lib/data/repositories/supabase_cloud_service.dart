import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/user_entity.dart';

class SupabaseCloudService {
  SupabaseCloudService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // 🔥 1. PRODUCTS - المنتجات
  // ===========================================================================

  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId) {
    debugPrint('🔍 [Products] Stream للمورد: $vendorId');
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .map((maps) {
      debugPrint('📦 [Products] تم استلام ${maps.length} منتج للمورد');
      return maps.map((m) => ProductEntity.fromMap(m)).toList();
    });
  }

  Stream<List<ProductEntity>> getAllProductsStream() {
    debugPrint('🔍 [Products] Stream لجميع المنتجات (للعميل)');
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) {
      debugPrint('📦 [Products] تم استلام ${maps.length} منتج إجمالي');
      return maps.map((m) => ProductEntity.fromMap(m)).toList();
    });
  }

  Future<void> rpcAddProduct(String vendorId, ProductEntity product) async {
    try {
      debugPrint('➕ [Products-RPC] إضافة/تحديث منتج: ${product.name}');
      final imageUrl = await _uploadLocalImageIfNeeded(product.imagePath);
      final toSave = imageUrl == product.imagePath ? product : product.copyWith(imagePath: imageUrl);

      final result = await _supabase.rpc('vendor_add_product', params: {
        'p_vendor_id': vendorId,
        'p_product': toSave.toMap(),
      });
      debugPrint('✅ [Products-RPC] تم العملية بنجاح: $result');
    } catch (e) {
      debugPrint('❌ [Products-RPC] خطأ في العملية: $e');
      rethrow;
    }
  }

  Future<String?> _uploadLocalImageIfNeeded(String? path) async {
    if (path == null || path.isEmpty || path.startsWith('http')) return path;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final ext = path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      await _supabase.storage.from('product-images').upload(fileName, file);
      return _supabase.storage.from('product-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('⚠️ [Storage] تعذر رفع الصورة، سيتم الحفظ بدون صورة: $e');
      return null;
    }
  }

  Future<void> rpcUpdateProduct(String vendorId, String productId, Map<String, dynamic> patch) async {
    try {
      debugPrint('✏️ [Products-RPC] تعديل منتج: $productId');
      await _supabase.rpc('vendor_update_product', params: {
        'p_vendor_id': vendorId,
        'p_product_id': productId,
        'p_patch': patch,
      });
      debugPrint('✅ [Products-RPC] تم التعديل بنجاح');
    } catch (e) {
      debugPrint('❌ [Products-RPC] خطأ في التعديل: $e');
      rethrow;
    }
  }

  Future<void> rpcDeleteProduct(String vendorId, String productId) async {
    try {
      debugPrint('🗑️ [Products-RPC] حذف منتج: $productId');
      await _supabase.rpc('vendor_delete_product', params: {
        'p_vendor_id': vendorId,
        'p_product_id': productId,
      });
      debugPrint('✅ [Products-RPC] تم الحذف بنجاح');
    } catch (e) {
      debugPrint('❌ [Products-RPC] خطأ في الحذف: $e');
      rethrow;
    }
  }

  Future<void> decrementOfferStock(String productId, int qty) async {
    try {
      final row = await _supabase
          .from('products')
          .select('offer_remaining_qty')
          .eq('id', productId)
          .single();

      final current = row['offer_remaining_qty'] ?? 0;
      final newQty = current - qty;

      await _supabase
          .from('products')
          .update({'offer_remaining_qty': newQty < 0 ? 0 : newQty})
          .eq('id', productId);

      debugPrint('✅ [Products] تم خصم $qty من عرض $productId. المتبقي: $newQty');
    } catch (e) {
      debugPrint('❌ [Products] خطأ في خصم المخزون: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 🔥 2. ORDERS - الطلبات
  // ===========================================================================

  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false)
        .asyncMap((maps) => _enrichOrdersWithItems(maps));
  }

  Stream<List<OrderEntity>> getClientOrdersStream(String clientId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .asyncMap((maps) => _enrichOrdersWithItems(maps));
  }

  Stream<List<OrderEntity>> getAllOrdersStream() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((maps) => _enrichOrdersWithItems(maps));
  }

  Future<void> addOrder(OrderEntity order) async {
    try {
      await _supabase.from('orders').insert(order.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderItem(String orderId, String productId, int newQty) async {
    try {
      await _supabase.rpc('update_order_item_atomic', params: {
        'p_order_id': orderId,
        'p_product_id': productId,
        'p_new_qty': newQty,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderInfo(String orderId, {String? name, String? phone, String? address}) async {
    final data = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) data['client_name'] = name;
    if (phone != null) data['client_phone'] = phone;
    if (address != null) data['client_address'] = address;
    await _supabase.from('orders').update(data).eq('id', orderId);
  }

  Future<void> deleteOrder(String orderId) async {
    await _supabase.from('orders').delete().eq('id', orderId);
  }

  Future<bool> placeOrdersAtomic(List<OrderEntity> orders) async {
    if (orders.isEmpty) return true;
    final payload = [
      for (final o in orders)
        {
          ...o.toMap(),
          'items': [for (final it in o.items) it.toMap()],
        },
    ];
    try {
      await _supabase.rpc('place_orders_atomic', params: {'p_orders': payload});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 🔥 3. ORDER ITEMS - بنود الطلبات
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getOrderItemsStream(String orderId) {
    return _supabase
        .from('order_items')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  Future<void> addOrderItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await _supabase.from('order_items').insert(items);
  }

  Future<void> deleteOrderItem(String itemId) async {
    await _supabase.from('order_items').delete().eq('id', itemId);
  }

  // ===========================================================================
  // 🔥 4. PROFILES - الملفات الشخصية
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getAllProfilesStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  Stream<List<Map<String, dynamic>>> getVendorsStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'vendor')
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  Future<Map<String, dynamic>?> getProfileByPhone(String phone) async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('phone', phone)
        .maybeSingle();
  }

  Stream<UserEntity?> getMyProfileStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((maps) => maps.isEmpty ? null : UserEntity.fromMap(maps.first));
  }

  Future<void> addProfile(Map<String, dynamic> data) async {
    await _supabase.from('profiles').upsert(data);
  }

  Future<void> deleteProfile(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
  }

  Future<void> rpcAddVendor(String adminId, Map<String, dynamic> vendorData) async {
    await _supabase.rpc('admin_add_vendor', params: {
      'p_admin_id': adminId,
      'p_vendor': vendorData,
    });
  }

  Future<void> rpcSetVendorStatus(String adminId, String vendorId, String status) async {
    await _supabase.rpc('admin_set_vendor_status', params: {
      'p_admin_id': adminId,
      'p_vendor_id': vendorId,
      'p_status': status,
    });
  }

  // ===========================================================================
  // 🔥 5. CATEGORIES - التصنيفات
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  Future<void> rpcAddCategory(String adminId, String name, {String? icon}) async {
    await _supabase.rpc('admin_add_category', params: {
      'p_admin_id': adminId,
      'p_name': name,
      'p_icon': icon ?? 'category',
    });
  }

  Future<void> rpcUpdateCategory(String adminId, String categoryId, String name, {String? icon}) async {
    await _supabase.rpc('admin_update_category', params: {
      'p_admin_id': adminId,
      'p_category_id': categoryId,
      'p_name': name,
      'p_icon': icon ?? 'category',
    });
  }

  Future<void> rpcDeleteCategory(String adminId, String categoryId) async {
    await _supabase.rpc('admin_delete_category', params: {
      'p_admin_id': adminId,
      'p_category_id': categoryId,
    });
  }

  // ===========================================================================
  // 🔥 6. NOTIFICATIONS - الإشعارات
  // ===========================================================================

  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  Future<void> addNotification(Map<String, dynamic> data) async {
    await _supabase.from('notifications').insert(data);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
  }

  // ===========================================================================
  // 🔥 7. SETTINGS - الإعدادات
  // ===========================================================================

  Stream<Map<String, dynamic>?> getSettingsStream(String id) {
    return _supabase
        .from('settings')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((maps) => maps.isEmpty ? null : maps.first);
  }

  Future<void> upsertSettings(String id, Map<String, dynamic> data) async {
    await _supabase.from('settings').upsert({
      'id': id,
      'data': data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ===========================================================================
  // 🔥 8. HELPERS
  // ===========================================================================

  Future<List<OrderEntity>> _enrichOrdersWithItems(List<Map<String, dynamic>> maps) async {
    if (maps.isEmpty) return [];
    final orders = maps.map((m) => OrderEntity.fromMap(m)).toList();
    try {
      final orderIds = orders.map((o) => o.id).toList();
      final itemsRows = List<Map<String, dynamic>>.from(
        await _supabase.from('order_items').select().inFilter('order_id', orderIds),
      );
      if (itemsRows.isEmpty) return orders;

      final productIds = itemsRows
          .map((r) => r['product_id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      final productsById = <String, ProductEntity>{};
      if (productIds.isNotEmpty) {
        final prodRows = List<Map<String, dynamic>>.from(
          await _supabase.from('products').select().inFilter('id', productIds),
        );
        for (final r in prodRows) {
          final p = ProductEntity.fromMap(r);
          productsById[p.id] = p;
        }
      }

      final itemsByOrder = <String, List<OrderItemEntity>>{};
      for (final r in itemsRows) {
        final oid = r['order_id']?.toString() ?? '';
        final pid = r['product_id']?.toString() ?? '';
        final qty = (r['qty'] as num?)?.toInt() ?? 1;
        final unitPrice = (r['unit_price'] as num?)?.toDouble() ?? 0.0;
        final product = productsById[pid] ??
            ProductEntity(id: pid, vendorId: '', name: 'صنف محذوف', category: '', price: unitPrice, unit: '');
        itemsByOrder.putIfAbsent(oid, () => []).add(
              OrderItemEntity(product: product, qty: qty, unitPrice: unitPrice),
            );
      }

      return [
        for (final o in orders)
          OrderEntity(
            id: o.id,
            parentOrderId: o.parentOrderId,
            vendorId: o.vendorId,
            clientId: o.clientId,
            clientName: o.clientName,
            clientPhone: o.clientPhone,
            clientAddress: o.clientAddress,
            items: itemsByOrder[o.id] ?? [],
            total: o.total,
            savings: o.savings,
            createdAt: o.createdAt,
            status: o.status,
            paymentMethod: o.paymentMethod,
          ),
      ];
    } catch (e) {
      debugPrint('⚠️ [Orders] تعذر إرفاق بنود الطلبات، سيتم عرضها بدون تفاصيل: $e');
      return orders;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await _supabase.from('categories').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> deleteCategoryByName(String name) async {
    await _supabase.from('categories').delete().eq('name', name);
  }

  Stream<List<Map<String, dynamic>>> getAllNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }
}
