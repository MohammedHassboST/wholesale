// lib/services/supabase_cloud_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_entity.dart';

class SupabaseCloudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // 🔥 1. PRODUCTS - المنتجات
  // ===========================================================================

  /// Stream: جلب منتجات مورد معين (لحظي)
  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId) {
    print('🔍 [Products] Stream للمورد: $vendorId');
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .map((maps) {
      print('📦 [Products] تم استلام ${maps.length} منتج للمورد');
      return maps.map((m) => ProductEntity.fromMap(m)).toList();
    });
  }

  /// Stream: جلب جميع المنتجات (للعميل - لحظي)
  Stream<List<ProductEntity>> getAllProductsStream() {
    print('🔍 [Products] Stream لجميع المنتجات (للعميل)');
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) {
      print('📦 [Products] تم استلام ${maps.length} منتج إجمالي');
      return maps.map((m) => ProductEntity.fromMap(m)).toList();
    });
  }

  /// إضافة منتج جديد أو تحديثه
  Future<void> addProduct(ProductEntity product) async {
    try {
      print('➕ [Products] إضافة/تحديث منتج: ${product.name}');
      await _supabase.from('products').upsert(product.toMap());
      print('✅ [Products] تم العملية بنجاح');
    } catch (e) {
      print('❌ [Products] خطأ في العملية: $e');
      rethrow;
    }
  }

  /// تعديل منتج
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      print('✏️ [Products] تعديل منتج: $id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('products').update(data).eq('id', id);
      print('✅ [Products] تم التعديل بنجاح');
    } catch (e) {
      print('❌ [Products] خطأ في التعديل: $e');
      rethrow;
    }
  }

  /// حذف منتج
  Future<void> deleteProduct(String id) async {
    try {
      print('🗑️ [Products] حذف منتج: $id');
      await _supabase.from('products').delete().eq('id', id);
      print('✅ [Products] تم الحذف بنجاح');
    } catch (e) {
      print('❌ [Products] خطأ في الحذف: $e');
      rethrow;
    }
  }

  /// خصم كمية من عرض (Offer)
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

      print('✅ [Products] تم خصم $qty من عرض $productId. المتبقي: $newQty');
    } catch (e) {
      print('❌ [Products] خطأ في خصم المخزون: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 🔥 2. ORDERS - الطلبات
  // ===========================================================================

  /// Stream: طلبات مورد معين
  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', vendorId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((m) => OrderEntity.fromMap(m)).toList());
  }

  /// Stream: طلبات عميل معين
  Stream<List<OrderEntity>> getClientOrdersStream(String clientId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((m) => OrderEntity.fromMap(m)).toList());
  }

  /// Stream: جميع الطلبات (للمدير)
  Stream<List<OrderEntity>> getAllOrdersStream() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.map((m) => OrderEntity.fromMap(m)).toList());
  }

  /// إضافة طلب
  Future<void> addOrder(OrderEntity order) async {
    try {
      await _supabase.from('orders').insert(order.toMap());
      print('✅ [Orders] تم إضافة الطلب: ${order.id}');
    } catch (e) {
      print('❌ [Orders] خطأ في الإضافة: $e');
      rethrow;
    }
  }

  /// تعديل حالة طلب
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      print('✅ [Orders] تم تحديث حالة الطلب $orderId إلى $newStatus');
    } catch (e) {
      print('❌ [Orders] خطأ في التحديث: $e');
      rethrow;
    }
  }

  /// حذف طلب
  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.from('orders').delete().eq('id', orderId);
      print('✅ [Orders] تم حذف الطلب: $orderId');
    } catch (e) {
      print('❌ [Orders] خطأ في الحذف: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 🔥 3. ORDER ITEMS - بنود الطلبات
  // ===========================================================================

  /// Stream: بنود طلب معين
  Stream<List<Map<String, dynamic>>> getOrderItemsStream(String orderId) {
    return _supabase
        .from('order_items')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map((maps) => List<Map<String, dynamic>>.from(maps));
  }

  /// إضافة بنود لطلب (دفعة واحدة)
  Future<void> addOrderItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      await _supabase.from('order_items').insert(items);
      print('✅ [OrderItems] تم إضافة ${items.length} بند');
    } catch (e) {
      print('❌ [OrderItems] خطأ في الإضافة: $e');
      rethrow;
    }
  }

  /// حذف بند
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
    final result = await _supabase
        .from('profiles')
        .select()
        .eq('phone', phone)
        .maybeSingle();
    return result;
  }

  Future<void> addProfile(Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').upsert(data);
      print('✅ [Profiles] تم إضافة/تحديث الحساب: ${data['id']}');
    } catch (e) {
      print('❌ [Profiles] خطأ في العملية: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(data).eq('id', id);
      print('✅ [Profiles] تم تحديث الحساب: $id');
    } catch (e) {
      print('❌ [Profiles] خطأ في التحديث: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
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

  Future<void> addCategory(Map<String, dynamic> data) async {
    await _supabase.from('categories').insert(data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _supabase.from('categories').update(data).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
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
}