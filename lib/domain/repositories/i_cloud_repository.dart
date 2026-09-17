import '../entities/product_entity.dart';
import '../entities/order_entity.dart';
import '../entities/notification_entity.dart';
import '../entities/user_entity.dart';

abstract class ICloudRepository {
  // ─── المستخدمين والموردين ───
  Stream<List<UserEntity>> getVendorsStream();
  Future<void> saveUser(UserEntity user);
  Future<void> updateVendorStatus(String vendorId, String status);
  Future<void> deleteVendor(String vendorId);

  // ─── المنتجات والعروض ───
  Stream<List<ProductEntity>> getProductsStream();
  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId);
  Future<void> addProduct(ProductEntity product);
  Future<void> updateProductStock(String productId, int newStock);
  Future<void> deleteProduct(String productId);

  // ─── التصنيفات (حصرية للمدير) ───
  Stream<List<String>> getCategoriesStream();
  Future<void> updateCategories(List<String> categories);
  Future<void> addCategory(String category);
  Future<void> deleteCategory(String category);

  // ─── الطلبات ───
  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId);
  Stream<List<OrderEntity>> getClientOrdersStream(String clientId);
  Stream<List<OrderEntity>> getOrdersStream();
  Future<void> placeOrders(List<OrderEntity> orders);
  Future<bool> placeOrdersWithAtomicStockCheck(List<OrderEntity> orders);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> deleteOrder(String orderId);

  // ─── الإشعارات ───
  Stream<List<NotificationEntity>> getNotificationsStream();
  Future<void> sendNotification(NotificationEntity notification);

  // ─── تهيئة البيانات الحسابية ───
  Future<void> seedInitialData();
}