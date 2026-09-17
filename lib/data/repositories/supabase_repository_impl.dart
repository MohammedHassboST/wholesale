import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_cloud_repository.dart';
import 'supabase_cloud_service.dart';

class SupabaseRepositoryImpl implements ICloudRepository {
  final SupabaseCloudService _service = SupabaseCloudService();

  @override
  Stream<List<UserEntity>> getVendorsStream() {
    return _service.getVendorsStream().map(
          (maps) => maps.map((m) => UserEntity.fromMap(m)).toList(),
        );
  }

  @override
  Future<void> saveUser(UserEntity user) async {
    await _service.addProfile(user.toMap());
  }

  @override
  Future<UserEntity?> getUserByPhone(String phone) async {
    final m = await _service.getProfileByPhone(phone);
    if (m == null) return null;
    return UserEntity.fromMap(m);
  }

  @override
  Stream<UserEntity?> getMyProfileStream(String userId) {
    return _service.getMyProfileStream(userId);
  }

  @override
  Future<void> updateVendorStatus(String adminId, String vendorId, String status) async {
    await _service.rpcSetVendorStatus(adminId, vendorId, status);
  }

  @override
  Future<void> deleteVendor(String adminId, String vendorId) async {
    await _service.deleteProfile(vendorId);
  }

  @override
  Stream<List<ProductEntity>> getProductsStream() {
    return _service.getAllProductsStream();
  }

  @override
  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId) {
    return _service.getVendorProductsStream(vendorId);
  }

  @override
  Future<void> addProduct(String vendorId, ProductEntity product) async {
    await _service.rpcAddProduct(vendorId, product);
  }

  @override
  Future<void> updateProduct(String vendorId, String productId, Map<String, dynamic> patch) async {
    await _service.rpcUpdateProduct(vendorId, productId, patch);
  }

  @override
  Future<void> deleteProduct(String vendorId, String productId) async {
    await _service.rpcDeleteProduct(vendorId, productId);
  }

  @override
  Stream<List<String>> getCategoriesStream() {
    return _service.getCategoriesStream().map(
          (maps) => maps.map((m) => m['name'] as String).toList(),
        );
  }

  @override
  Future<void> updateCategories(List<String> categories) async {
    // Diff against stored rows so removals actually delete and re-syncs
    // don't create duplicates.
    final existing = (await _service.fetchCategories())
        .map((m) => (m['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toSet();
    final desired = categories.where((c) => c.isNotEmpty).toSet();
    for (final name in desired.difference(existing)) {
      await _service.rpcAddCategory('SYSTEM', name);
    }
    for (final name in existing.difference(desired)) {
      final all = await _service.fetchCategories();
      final cat = all.firstWhere((c) => c['name'] == name, orElse: () => {});
      if (cat.isNotEmpty) {
        await _service.rpcDeleteCategory('SYSTEM', cat['id']);
      }
    }
  }

  @override
  Future<void> addCategory(String adminId, String category, {String? icon}) async {
    await _service.rpcAddCategory(adminId, category, icon: icon);
  }

  @override
  Future<void> updateCategory(String adminId, String oldName, String newName, {String? icon}) async {
    final all = await _service.fetchCategories();
    final cat = all.firstWhere((c) => c['name'] == oldName, orElse: () => {});
    if (cat.isNotEmpty) {
      await _service.rpcUpdateCategory(adminId, cat['id'], newName, icon: icon);
    }
  }

  @override
  Future<void> deleteCategory(String adminId, String category) async {
    final all = await _service.fetchCategories();
    final cat = all.firstWhere((c) => c['name'] == category, orElse: () => {});
    if (cat.isNotEmpty) {
      await _service.rpcDeleteCategory(adminId, cat['id']);
    }
  }

  @override
  Future<void> saveVendorByAdmin(String adminId, UserEntity vendor) async {
    await _service.rpcAddVendor(adminId, vendor.toMap());
  }

  @override
  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId) {
    return _service.getVendorOrdersStream(vendorId);
  }

  @override
  Stream<List<OrderEntity>> getClientOrdersStream(String clientId) {
    return _service.getClientOrdersStream(clientId);
  }

  @override
  Stream<List<OrderEntity>> getOrdersStream() {
    return _service.getAllOrdersStream();
  }

  @override
  Future<void> placeOrders(List<OrderEntity> orders) async {
    for (var order in orders) {
      await _service.addOrder(order);
      // Also add order items
      final itemsMap = order.items.map((item) {
        final m = item.toMap();
        m['order_id'] = order.id;
        return m;
      }).toList();
      await _service.addOrderItems(itemsMap);
    }
  }

  @override
  Future<bool> placeOrdersWithAtomicStockCheck(List<OrderEntity> orders) async {
    // Single source of truth: ONE Postgres transaction (row locks + stock
    // verify + decrement + order/item inserts + vendor & low-stock alerts).
    // Deliberately NO client-side fallback — a fallback could oversell.
    // Requires the `place_orders_atomic` RPC from supabase/migrations.
    return _service.placeOrdersAtomic(orders);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _service.updateOrderStatus(orderId, status);
  }

  @override
  Future<void> updateOrderItem(String orderId, String productId, int newQty) async {
    await _service.updateOrderItem(orderId, productId, newQty);
  }

  @override
  Future<void> updateOrderInfo(String orderId, {String? name, String? phone, String? address}) async {
    await _service.updateOrderInfo(orderId, name: name, phone: phone, address: address);
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await _service.deleteOrder(orderId);
  }

  @override
  Stream<List<NotificationEntity>> getNotificationsStream() {
    return _service.getAllNotificationsStream().map(
          (maps) => maps
              .map((m) => NotificationEntity.fromMap(m['id']?.toString() ?? '', m))
              .toList(),
        );
  }

  @override
  Future<void> sendNotification(NotificationEntity notification) async {
    await _service.addNotification(notification.toMap());
  }

  @override
  Future<void> seedInitialData() async {
    // Placeholder
  }
}
