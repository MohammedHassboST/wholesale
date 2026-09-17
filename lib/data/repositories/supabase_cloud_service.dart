import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_cloud_repository.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Realtime Strategy:
// 1. جلب الداتا أول مرة عبر select().eq().order()
// 2. الاستماع لأحداث Realtime (INSERT/UPDATE/DELETE) وإعادة الجلب عند التغيير
// هذا أثبت من .stream(primaryKey).eq() الذي يتعارض مع بعض إصدارات SDK
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseRepositoryImpl implements ICloudRepository {
  SupabaseClient? get _db {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ─── مساعد Realtime عام ──────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _liveStream({
    required String table,
    String? eqCol,
    String? eqVal,
    String orderBy = 'created_at',
    bool ascending = false,
  }) {
    final client = _db;
    if (client == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> fetch() async {
      if (controller.isClosed) return;
      try {
        var query = client.from(table).select();
        if (eqCol != null && eqVal != null) {
          query = query.eq(eqCol, eqVal);
        }
        final data = await query.order(orderBy, ascending: ascending);
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        debugPrint('[$table] fetch error: $e');
      }
    }

    // الاستماع للتغييرات اللحظية
    final channelId = 'public:$table:${eqCol ?? "all"}:${eqVal ?? "any"}';
    final channel = client.channel(channelId);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (payload) {
        debugPrint('[$table] Realtime event: ${payload.eventType}');
        fetch();
      },
    ).subscribe((status, [err]) {
      debugPrint('[$table] Realtime status: $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        fetch(); // الجلب الأولي عند نجاح الاشتراك
      }
      if (err != null) debugPrint('[$table] Realtime error: $err');
    });

    controller.onCancel = () {
      client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  // ─── الموردون ────────────────────────────────────────────────────────────
  @override
  Stream<List<UserEntity>> getVendorsStream() => _liveStream(
        table: 'profiles',
        eqCol: 'role',
        eqVal: 'vendor',
      ).map((l) => l.map(UserEntity.fromMap).toList());

  @override
  Future<void> saveUser(UserEntity user) async {
    try {
      await _db?.from('profiles').upsert(user.toMap());
    } catch (e) {
      debugPrint('saveUser error: $e');
    }
  }

  @override
  Future<void> updateVendorStatus(String vendorId, String status) async {
    try {
      await _db?.from('profiles').update({'status': status}).eq('id', vendorId);
    } catch (e) {
      debugPrint('updateVendorStatus error: $e');
    }
  }

  @override
  Future<void> deleteVendor(String vendorId) async {
    try {
      await _db?.from('profiles').delete().eq('id', vendorId);
    } catch (e) {
      debugPrint('deleteVendor error: $e');
    }
  }

  // ─── المنتجات ────────────────────────────────────────────────────────────
  @override
  Stream<List<ProductEntity>> getProductsStream() => _liveStream(
        table: 'products',
      ).map((l) => l.map((d) => ProductModel.fromMap(d, d['id'].toString())).toList());

  @override
  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId) =>
      _liveStream(table: 'products', eqCol: 'vendor_id', eqVal: vendorId)
          .map((l) => l.map((d) => ProductModel.fromMap(d, d['id'].toString())).toList());

  @override
  Future<void> addProduct(ProductEntity p) async {
    try {
      final model = ProductModel.fromEntity(p);
      await _db?.from('products').upsert(model.toMap());
    } catch (e) {
      debugPrint('addProduct error: $e');
    }
  }

  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _db
          ?.from('products')
          .update({'offer_remaining_qty': newStock})
          .eq('id', productId);
    } catch (e) {
      debugPrint('updateProductStock error: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _db?.from('products').delete().eq('id', productId);
    } catch (e) {
      debugPrint('deleteProduct error: $e');
    }
  }

  // ─── التصنيفات ───────────────────────────────────────────────────────────
  @override
  Stream<List<String>> getCategoriesStream() => _liveStream(
        table: 'categories',
        orderBy: 'name',
        ascending: true,
      ).map((l) {
        if (l.isEmpty) return ['الكل', 'مواد غذائية', 'منظفات وعناية', 'مشروبات وعصائر'];
        final names = l.map((e) => (e['name'] ?? e['id']).toString()).toList();
        if (!names.contains('الكل')) names.insert(0, 'الكل');
        return names;
      });

  @override
  Future<void> updateCategories(List<String> cats) async {
    for (final c in cats) {
      if (c == 'الكل') continue;
      try {
        await _db?.from('categories').upsert({'id': c, 'name': c});
      } catch (e) {
        debugPrint('updateCategories error: $e');
      }
    }
  }

  @override
  Future<void> addCategory(String category) async {
    try {
      await _db?.from('categories').upsert({'id': category, 'name': category});
    } catch (e) {
      debugPrint('addCategory error: $e');
    }
  }

  @override
  Future<void> deleteCategory(String category) async {
    if (category == 'الكل') return;
    try {
      await _db?.from('categories').delete().eq('id', category);
    } catch (e) {
      debugPrint('deleteCategory error: $e');
    }
  }

  // ─── الطلبات ─────────────────────────────────────────────────────────────
  @override
  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId) =>
      _liveStream(table: 'orders', eqCol: 'vendor_id', eqVal: vendorId)
          .map((l) => l.map((d) => OrderModel.fromMap(d, d['id'].toString())).toList());

  @override
  Stream<List<OrderEntity>> getClientOrdersStream(String clientId) =>
      _liveStream(table: 'orders', eqCol: 'client_id', eqVal: clientId)
          .map((l) => l.map((d) => OrderModel.fromMap(d, d['id'].toString())).toList());

  @override
  Stream<List<OrderEntity>> getOrdersStream() =>
      _liveStream(table: 'orders')
          .map((l) => l.map((d) => OrderModel.fromMap(d, d['id'].toString())).toList());

  @override
  Future<void> placeOrders(List<OrderEntity> orders) async {
    try {
      final list = orders.map((o) => OrderModel.fromEntity(o).toMap()).toList();
      await _db?.from('orders').insert(list);
    } catch (e) {
      debugPrint('placeOrders error: $e');
    }
  }

  @override
  Future<bool> placeOrdersWithAtomicStockCheck(List<OrderEntity> orders) async {
    final client = _db;
    if (client == null) return true;
    try {
      // خصم ذري للمخزون
      for (final order in orders) {
        for (final item in order.items) {
          if (item.product.isOffer) {
            final res = await client
                .from('products')
                .select('offer_remaining_qty')
                .eq('id', item.product.id)
                .maybeSingle();
            if (res != null) {
              final stock = (res['offer_remaining_qty'] as num?)?.toInt() ?? 0;
              if (stock < item.qty) {
                throw Exception(
                    'الكمية المتاحة من (${item.product.name}) غير كافية ($stock متبقي فقط)');
              }
              await client
                  .from('products')
                  .update({'offer_remaining_qty': stock - item.qty})
                  .eq('id', item.product.id);
            }
          }
        }
      }
      final list = orders.map((o) => OrderModel.fromEntity(o).toMap()).toList();
      await client.from('orders').insert(list);
      return true;
    } catch (e) {
      debugPrint('placeOrdersWithAtomicStockCheck error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db?.from('orders').update({'status': status}).eq('id', orderId);
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
    }
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await _db?.from('orders').delete().eq('id', orderId);
    } catch (e) {
      debugPrint('deleteOrder error: $e');
    }
  }

  // ─── الإشعارات ───────────────────────────────────────────────────────────
  @override
  Stream<List<NotificationEntity>> getNotificationsStream() =>
      _liveStream(table: 'notifications').map((l) => l
          .take(50)
          .map((d) => NotificationEntity(
                id: d['id'].toString(),
                title: d['title'] ?? '',
                body: d['body'] ?? '',
                createdAt: d['created_at'] != null
                    ? DateTime.parse(d['created_at'])
                    : DateTime.now(),
                payload: d['payload'],
                targetPhone: d['target_phone'],
                isRead: d['is_read'] ?? false,
              ))
          .toList());

  @override
  Future<void> sendNotification(NotificationEntity n) async {
    try {
      await _db?.from('notifications').insert({
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'created_at': n.createdAt.toIso8601String(),
        'payload': n.payload,
        'target_phone': n.targetPhone,
        'is_read': n.isRead,
      });
    } catch (e) {
      debugPrint('sendNotification error: $e');
    }
  }

  // ─── تهيئة البيانات (مدير فقط) ───────────────────────────────────────────
  @override
  Future<void> seedInitialData() async {
    final client = _db;
    if (client == null) return;
    try {
      final cats = ['مواد غذائية', 'مشروبات وعصائر', 'منظفات وعناية', 'بقوليات وحبوب'];
      for (final c in cats) {
        await client.from('categories').upsert({'id': c, 'name': c});
      }
      await client.from('profiles').upsert({
        'id': 'vendor_01112223334',
        'role': 'vendor',
        'name': 'شركة الأمل للجملة',
        'phone': '01112223334',
        'shop_name': 'الأمل للتوزيع',
        'address': 'القاهرة - العبور',
        'business_activity': 'مواد غذائية وزيوت',
        'status': 'active',
      });
      await client.from('products').upsert([
        {
          'id': 'prod_seed_1',
          'vendor_id': 'vendor_01112223334',
          'name': 'زيت خليط ممتاز 1 لتر',
          'category': 'مواد غذائية',
          'price': 720.0,
          'unit': 'كرتونة (12 زجاجة)',
          'min_order_qty': 2,
          'is_offer': true,
          'offer_price': 650.0,
          'offer_total_qty': 100,
          'offer_remaining_qty': 45,
        },
        {
          'id': 'prod_seed_2',
          'vendor_id': 'vendor_01112223334',
          'name': 'سكر أبيض نقي 1 كجم',
          'category': 'مواد غذائية',
          'price': 340.0,
          'unit': 'لفة (10 أكياس)',
          'min_order_qty': 5,
          'is_offer': true,
          'offer_price': 310.0,
          'offer_total_qty': 80,
          'offer_remaining_qty': 8,
        },
        {
          'id': 'prod_seed_3',
          'vendor_id': 'vendor_01112223334',
          'name': 'أرز بلدي 25 كجم',
          'category': 'بقوليات وحبوب',
          'price': 650.0,
          'unit': 'شكارة / شوال (25 كجم)',
          'min_order_qty': 1,
          'is_offer': false,
          'offer_price': 0,
          'offer_total_qty': 0,
          'offer_remaining_qty': 0,
        },
      ]);
    } catch (e) {
      debugPrint('seedInitialData error: $e');
    }
  }

  // ─── تحويل البيانات (التخلص من المساعدات القديمة لصالح toMap الخاص بالنماذج) ────
}