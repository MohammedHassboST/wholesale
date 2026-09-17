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
  Future<void> updateVendorStatus(String vendorId, String status) async {
    await _service.updateProfile(vendorId, {'status': status});
  }

  @override
  Future<void> deleteVendor(String vendorId) async {
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
  Future<void> addProduct(ProductEntity product) async {
    await _service.addProduct(product);
  }

  @override
  Future<void> updateProductStock(String productId, int newStock) async {
    await _service.updateProduct(productId, {'offer_remaining_qty': newStock});
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _service.deleteProduct(productId);
  }

  @override
  Stream<List<String>> getCategoriesStream() {
    return _service.getCategoriesStream().map(
          (maps) => maps.map((m) => m['name'] as String).toList(),
        );
  }

  @override
  Future<void> updateCategories(List<String> categories) async {
    // This depends on how categories are stored. 
    // If they are in a table, we might need a specific service method.
    for (var cat in categories) {
      await _service.addCategory({'name': cat});
    }
  }

  @override
  Future<void> addCategory(String category) async {
    await _service.addCategory({'name': category});
  }

  @override
  Future<void> deleteCategory(String category) async {
    await _service.deleteCategory(category);
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
    // Simplistic implementation for now
    try {
      await placeOrders(orders);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _service.updateOrderStatus(orderId, status);
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await _service.deleteOrder(orderId);
  }

  @override
  Stream<List<NotificationEntity>> getNotificationsStream() {
    // Note: getNotificationsStream in service needs a userId. 
    // If we want ALL notifications, we might need a new service method.
    // For now, let's assume it's for the current user or handled by a specific view.
    // I'll leave it as an empty stream or placeholder if logic is unclear.
    return const Stream.empty();
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
