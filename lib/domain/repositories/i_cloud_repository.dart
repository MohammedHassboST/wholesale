import '../entities/product_entity.dart';
import '../entities/order_entity.dart';
import '../entities/notification_entity.dart';
import '../entities/user_entity.dart';

abstract class ICloudRepository {
  // ─── المستخدمين والموردين ───
  Stream<List<UserEntity>> getVendorsStream();
  Future<void> saveUser(UserEntity user);
  Future<UserEntity?> getUserByPhone(String phone);
  Stream<UserEntity?> getMyProfileStream(String userId);
  Future<void> updateVendorStatus(String adminId, String vendorId, String status);
  Future<void> deleteVendor(String adminId, String vendorId);

  // ─── المنتجات والعروض ───
  Stream<List<ProductEntity>> getProductsStream();
  Stream<List<ProductEntity>> getVendorProductsStream(String vendorId);
  Future<void> addProduct(String vendorId, ProductEntity product);
  Future<void> updateProduct(String vendorId, String productId, Map<String, dynamic> patch);
  Future<void> deleteProduct(String vendorId, String productId);

  // ─── التصنيفات (حصرية للمدير) ───
  Stream<List<String>> getCategoriesStream();
  Future<void> updateCategories(List<String> categories);
  Future<void> addCategory(String adminId, String category, {String? icon});
  Future<void> updateCategory(String adminId, String oldName, String newName, {String? icon});
  Future<void> deleteCategory(String adminId, String category);

  Future<void> saveVendorByAdmin(String adminId, UserEntity vendor);

  // ─── الطلبات ───
  Stream<List<OrderEntity>> getVendorOrdersStream(String vendorId);
  Stream<List<OrderEntity>> getClientOrdersStream(String clientId);
  Stream<List<OrderEntity>> getOrdersStream();
  Future<void> placeOrders(List<OrderEntity> orders);
  Future<bool> placeOrdersWithAtomicStockCheck(List<OrderEntity> orders);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> updateOrderItem(String orderId, String productId, int newQty);
  Future<void> updateOrderInfo(String orderId, {String? name, String? phone, String? address});
  Future<void> deleteOrder(String orderId);

  // ─── الإشعارات ───
  Stream<List<NotificationEntity>> getNotificationsStream();
  Future<void> sendNotification(NotificationEntity notification);

  // ─── تهيئة البيانات الحسابية ───
  Future<void> seedInitialData();
}