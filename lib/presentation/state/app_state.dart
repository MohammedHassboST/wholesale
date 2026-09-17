import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../domain/repositories/i_cloud_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/notification_entity.dart';

class CartItem {
  final ProductEntity product;
  int qty;
  final double unitPrice;

  CartItem({required this.product, required this.qty, required this.unitPrice});
}

class AppState extends ChangeNotifier {
  ICloudRepository get _cloud => GetIt.I<ICloudRepository>();

  UserEntity? currentUser;
  List<ProductEntity> products = [];
  List<OrderEntity> orders = [];
  List<UserEntity> vendors = [];
  List<NotificationEntity> notifications = [];
  List<String> categories = ['الكل', 'مواد غذائية', 'منظفات وعناية', 'مشروبات وعصائر', 'بقوليات وحبوب'];

  List<CartItem> cart = [];
  bool isCheckingOut = false;
  String currentLocale = 'ar'; // 'ar' (RTL) or 'en' (LTR)

  StreamSubscription? _productsSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _vendorsSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _notificationsSub;

  // ─── التوافق مع الملفات والبروفايل ───
  String _retailerEmail = '';
  String get retailerEmail => _retailerEmail;
  set retailerEmail(String v) { _retailerEmail = v; notifyListeners(); }

  int? _retailerAge;
  int? get retailerAge => _retailerAge;
  set retailerAge(int? v) { _retailerAge = v; notifyListeners(); }

  String _retailerAddress = '';
  String get retailerAddress => _retailerAddress;
  set retailerAddress(String v) { _retailerAddress = v; notifyListeners(); }

  DateTime retailerRegistrationDate = DateTime.now();

  String adminName = 'مدير عام المنصة';
  String adminEmail = '';
  int? adminAge;
  String adminAddress = '';

  AppState() {
    _loadSession();
  }

  bool get isRtl => currentLocale == 'ar';

  void toggleLocale() {
    currentLocale = currentLocale == 'ar' ? 'en' : 'ar';
    notifyListeners();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (id != null) {
      currentUser = UserEntity(
        id: id,
        name: prefs.getString('userName') ?? '',
        phone: prefs.getString('userPhone') ?? '',
        role: prefs.getString('userRole') ?? 'customer',
        shopName: prefs.getString('shopName'),
        address: prefs.getString('userAddress'),
        businessActivity: prefs.getString('businessActivity'),
        status: prefs.getString('userStatus') ?? 'active',
      );
      _initCloudSync();
    } else {
      _initPublicSync();
    }
  }

  Future<void> login(UserEntity user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
    await prefs.setString('userName', user.name);
    await prefs.setString('userPhone', user.phone);
    await prefs.setString('userRole', user.role);
    await prefs.setString('userStatus', user.status);
    if (user.shopName != null) await prefs.setString('shopName', user.shopName!);
    if (user.address != null) await prefs.setString('userAddress', user.address!);
    if (user.businessActivity != null) await prefs.setString('businessActivity', user.businessActivity!);

    await _cloud.saveUser(user);
    _initCloudSync();
    notifyListeners();
  }

  void logout() async {
    currentUser = null;
    cart.clear();
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _vendorsSub?.cancel();
    _categoriesSub?.cancel();
    _notificationsSub?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _initPublicSync();
    notifyListeners();
  }

  void _initPublicSync() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();

    _categoriesSub = _cloud.getCategoriesStream().listen((list) {
      categories = list;
      notifyListeners();
    });

    _productsSub = _cloud.getProductsStream().listen((list) {
      products = list;
      notifyListeners();
    });
  }

  void _initCloudSync() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _vendorsSub?.cancel();
    _categoriesSub?.cancel();
    _notificationsSub?.cancel();

    if (currentUser == null) return;

    _categoriesSub = _cloud.getCategoriesStream().listen((list) {
      categories = list;
      notifyListeners();
    });

    _notificationsSub = _cloud.getNotificationsStream().listen((list) {
      notifications = list;
      notifyListeners();
    });

    if (currentUser!.role == 'vendor') {
      _productsSub = _cloud.getVendorProductsStream(currentUser!.id).listen((list) {
        products = list;
        notifyListeners();
      });
      _ordersSub = _cloud.getVendorOrdersStream(currentUser!.id).listen((list) {
        orders = list;
        notifyListeners();
      });
    } else if (currentUser!.role == 'super_admin') {
      _productsSub = _cloud.getProductsStream().listen((list) {
        products = list;
        notifyListeners();
      });
      _ordersSub = _cloud.getOrdersStream().listen((list) {
        orders = list;
        notifyListeners();
      });
      _vendorsSub = _cloud.getVendorsStream().listen((list) {
        vendors = list;
        notifyListeners();
      });
    } else {
      _productsSub = _cloud.getProductsStream().listen((list) {
        products = list;
        notifyListeners();
      });
      _ordersSub = _cloud.getClientOrdersStream(currentUser!.id).listen((list) {
        orders = list;
        notifyListeners();
      });
    }
  }

  // ─── Getters & Helpers ───
  String? get currentPhone => currentUser?.phone;
  String? get currentName => currentUser?.name;
  set currentName(String? v) {
    if (currentUser != null && v != null) {
      currentUser = UserEntity(
        id: currentUser!.id, name: v, phone: currentUser!.phone, role: currentUser!.role,
        shopName: currentUser!.shopName, address: currentUser!.address,
        businessActivity: currentUser!.businessActivity, status: currentUser!.status,
      );
      _cloud.saveUser(currentUser!);
      notifyListeners();
    }
  }

  String? get shopName => currentUser?.shopName;
  set shopName(String? v) {
    if (currentUser != null) {
      currentUser = UserEntity(
        id: currentUser!.id, name: currentUser!.name, phone: currentUser!.phone, role: currentUser!.role,
        shopName: v, address: currentUser!.address,
        businessActivity: currentUser!.businessActivity, status: currentUser!.status,
      );
      _cloud.saveUser(currentUser!);
      notifyListeners();
    }
  }

  bool get isAdmin => currentUser?.role == 'super_admin';
  bool get isVendor => currentUser?.role == 'vendor';
  bool get isCustomer => currentUser?.role == 'customer';

  // ─── السلة وتقسيم الطلبات متعددة الموردين ───
  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty);
  double get cartTotal => cart.fold(0.0, (sum, item) => sum + (item.unitPrice * item.qty));
  double get cartTotalSavings => cart.fold(0.0, (sum, item) {
    if (item.unitPrice < item.product.price) {
      return sum + ((item.product.price - item.unitPrice) * item.qty);
    }
    return sum;
  });

  int qtyInCart(String pid) => cart.where((c) => c.product.id == pid).firstOrNull?.qty ?? 0;

  Map<String, List<CartItem>> get cartGroupedByVendor {
    Map<String, List<CartItem>> grouped = {};
    for (var item in cart) {
      grouped.putIfAbsent(item.product.vendorId, () => []).add(item);
    }
    return grouped;
  }

  double vendorSubtotal(String vendorId) {
    final items = cartGroupedByVendor[vendorId] ?? [];
    return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.qty));
  }

  final double minOrderValuePerVendor = 500.0;

  bool get isCartValidForCheckout {
    if (cart.isEmpty) return false;
    for (var vendorId in cartGroupedByVendor.keys) {
      if (vendorSubtotal(vendorId) < minOrderValuePerVendor) return false;
    }
    return true;
  }

  void addToCart(ProductEntity product) {
    final effectivePrice = product.currentPrice;
    final existing = cart.where((c) => c.product.id == product.id).firstOrNull;
    if (existing != null) {
      existing.qty += product.minOrderQty;
    } else {
      cart.add(CartItem(product: product, qty: product.minOrderQty, unitPrice: effectivePrice));
    }
    notifyListeners();
  }

  void changeQty(String productId, int newQty) {
    if (newQty <= 0) {
      cart.removeWhere((c) => c.product.id == productId);
    } else {
      final item = cart.firstWhere((c) => c.product.id == productId);
      if (newQty >= item.product.minOrderQty) {
        item.qty = newQty;
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  Future<bool> checkout() async {
    if (isCheckingOut || cart.isEmpty || currentUser == null || !isCartValidForCheckout) return false;
    isCheckingOut = true;
    notifyListeners();

    try {
      Map<String, List<CartItem>> vendorCarts = cartGroupedByVendor;
      List<OrderEntity> newOrders = [];
      final now = DateTime.now();
      final parentBatchId = 'BATCH-${now.millisecondsSinceEpoch}';

      for (var entry in vendorCarts.entries) {
        final vendorId = entry.key;
        final vendorItems = entry.value;

        double vTotal = 0;
        double vSavings = 0;
        List<OrderItemEntity> orderItems = [];

        for (var item in vendorItems) {
          vTotal += (item.unitPrice * item.qty);
          if (item.unitPrice < item.product.price) {
            vSavings += (item.product.price - item.unitPrice) * item.qty;
          }
          orderItems.add(OrderItemEntity(
            product: item.product,
            qty: item.qty,
            unitPrice: item.unitPrice,
          ));

          // فحص اقتراب نفاذ العرض عند 10%
          if (item.product.isOffer && item.product.offerTotalQty > 0) {
            int remaining = item.product.offerRemainingQty - item.qty;
            if (remaining < 0) remaining = 0;
            double pct = remaining / item.product.offerTotalQty;
            if (pct <= 0.10 && remaining > 0) {
              await _cloud.sendNotification(NotificationEntity(
                id: 'notif_low_${DateTime.now().millisecondsSinceEpoch}',
                title: '⚠️ تنبيه: العرض أوشك على النفاذ!',
                body: 'العرض على (${item.product.name}) لم يتبقَ منه سوى 10% فقط ($remaining ${item.product.unit})!',
                createdAt: now,
                payload: 'offer:${item.product.id}',
              ));
            }
          }
        }

        final subOrderId = 'ORD-${vendorId.length >= 4 ? vendorId.substring(vendorId.length - 4) : vendorId}-${now.millisecondsSinceEpoch.toString().substring(8)}';

        newOrders.add(OrderEntity(
          id: subOrderId,
          parentOrderId: parentBatchId,
          vendorId: vendorId,
          clientId: currentUser!.id,
          clientName: currentUser!.name,
          clientPhone: currentUser!.phone,
          clientAddress: currentUser!.address,
          items: orderItems,
          total: vTotal,
          savings: vSavings,
          createdAt: now,
          status: 'قيد المراجعة',
          paymentMethod: 'COD',
        ));

        // إشعار فوري للمورد
        await _cloud.sendNotification(NotificationEntity(
          id: 'notif_ven_${now.millisecondsSinceEpoch}_$vendorId',
          title: '📦 طلب فرعي جديد (كاش عند الاستلام)',
          body: 'وصلك طلب جديد من العميل (${currentUser!.name}) بإجمالي ${vTotal.toStringAsFixed(0)} ج.م',
          createdAt: now,
          targetPhone: vendorId,
          payload: 'order:$subOrderId',
        ));
      }

      // إرسال ذري يمنع التضارب والأوفرسيلنج
      await _cloud.placeOrdersWithAtomicStockCheck(newOrders);
      cart.clear();
      return true;
    } catch (e) {
      debugPrint("Checkout Error: $e");
      return false;
    } finally {
      isCheckingOut = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final order = orders.where((o) => o.id == orderId).firstOrNull;
    if (order != null && order.status == 'قيد المراجعة') {
      await updateOrderStatus(orderId, 'ملغي');
    }
  }

  List<ProductEntity> getProductsByCategory(String cat) {
    if (cat == 'الكل') return products;
    return products.where((p) => p.category == cat).toList();
  }

  // ─── إدارة الأصناف والعروض ───
  Future<void> addProduct(ProductEntity product) async {
    await _cloud.addProduct(product);

    final now = DateTime.now();
    if (product.isOffer) {
      await _cloud.sendNotification(NotificationEntity(
        id: 'notif_offer_${now.millisecondsSinceEpoch}',
        title: '🎉 عرض جديد متاح!',
        body: 'خصم مميز على (${product.name}) بسعر ${product.offerPrice} ج.م بدلاً من ${product.price} ج.م / ${product.unit}',
        createdAt: now,
        payload: 'offer:${product.id}',
      ));
    } else {
      await _cloud.sendNotification(NotificationEntity(
        id: 'notif_prod_${now.millisecondsSinceEpoch}',
        title: '📦 صنف جديد في سوق الجملة!',
        body: 'تم إضافة: (${product.name}) بسعر ${product.price} ج.م / ${product.unit} في قسم ${product.category}',
        createdAt: now,
        payload: 'product:${product.id}',
      ));
    }
  }

  Future<void> deleteProduct(String id) async => await _cloud.deleteProduct(id);

  void updateProduct(ProductEntity updatedProduct) {
    _cloud.addProduct(updatedProduct);
  }

  void updateProductStock(String productId, int newStock) {
    _cloud.updateProductStock(productId, newStock);
  }

  void createOffer(
    String productId,
    double offerPrice,
    int totalQty, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final p = products.firstWhere((pr) => pr.id == productId);
    final updated = p.copyWith(
      isOffer: true,
      offerPrice: offerPrice,
      offerTotalQty: totalQty,
      offerRemainingQty: totalQty,
      offerStartDate: startDate,
      offerEndDate: endDate,
    );
    await addProduct(updated);
  }

  void updateRetailerInfo({String? name, String? email, int? age, String? address}) {
    if (currentUser != null && name != null) {
      currentUser = UserEntity(
        id: currentUser!.id, name: name, phone: currentUser!.phone, role: currentUser!.role,
        shopName: currentUser!.shopName, address: address ?? currentUser!.address,
        businessActivity: currentUser!.businessActivity, status: currentUser!.status,
      );
    }
    if (email != null) _retailerEmail = email;
    if (age != null) _retailerAge = age;
    if (address != null) _retailerAddress = address;
    notifyListeners();
  }

  void updateAdminInfo({String? name, String? email, int? age, String? address}) {
    if (name != null) adminName = name;
    if (email != null) adminEmail = email;
    if (age != null) adminAge = age;
    if (address != null) adminAddress = address;
    notifyListeners();
  }

  void deleteOffer(String productId) async {
    final p = products.firstWhere((pr) => pr.id == productId);
    final updated = p.copyWith(
      isOffer: false,
      offerPrice: 0.0,
      offerTotalQty: 0,
      offerRemainingQty: 0,
      offerStartDate: null,
      offerEndDate: null,
    );
    await addProduct(updated);
  }

  // ─── تحكم المدير الحصري في التصنيفات ───
  Future<void> addCategory(String cat) async {
    if (!categories.contains(cat)) {
      categories.add(cat);
      await _cloud.addCategory(cat);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String cat) async {
    if (cat == 'الكل') return;
    categories.remove(cat);
    await _cloud.deleteCategory(cat);
    notifyListeners();
  }

  // ─── تحكم المدير في الموردين ───
  Future<void> updateVendorStatus(String vendorId, String status) async {
    await _cloud.updateVendorStatus(vendorId, status);
    final idx = vendors.indexWhere((v) => v.id == vendorId);
    if (idx != -1) {
      final v = vendors[idx];
      vendors[idx] = UserEntity(
        id: v.id, name: v.name, phone: v.phone, role: v.role, shopName: v.shopName,
        address: v.address, businessActivity: v.businessActivity, status: status,
      );
      notifyListeners();
    }
  }

  Future<void> deleteVendor(String vendorId) async {
    await _cloud.deleteVendor(vendorId);
    vendors.removeWhere((v) => v.id == vendorId);
    notifyListeners();
  }

  Future<void> addVendorByAdmin(UserEntity vendor) async {
    await _cloud.saveUser(vendor);
    vendors.add(vendor);
    notifyListeners();
  }

  // ─── تهيئة البيانات الحسابية (خاص بالمدير) ───
  Future<void> seedInitialData() async {
    await _cloud.seedInitialData();
  }

  // ─── حالات الطلبات ───
  Future<void> updateOrderStatus(String id, String status) async {
    await _cloud.updateOrderStatus(id, status);
    final order = orders.where((o) => o.id == id).firstOrNull;
    final now = DateTime.now();

    await _cloud.sendNotification(NotificationEntity(
      id: 'notif_status_${now.millisecondsSinceEpoch}',
      title: '📦 تحديث حالة طلبك',
      body: 'طلبك رقم #$id أصبح الآن: "$status"',
      createdAt: now,
      targetPhone: order?.clientPhone,
      payload: 'order:$id',
    ));
  }

  Future<void> deleteOrder(String orderId) async {
    await _cloud.deleteOrder(orderId);
    orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Future<void> acceptOrder(String id) async => await updateOrderStatus(id, 'مؤكد');
  Future<void> rejectOrder(String id) async => await updateOrderStatus(id, 'مرفوض');

  Future<void> advanceOrderStatus(String orderId, String currentStatus) async {
    String nextStatus = currentStatus;
    switch (currentStatus) {
      case 'قيد المراجعة': nextStatus = 'مؤكد'; break;
      case 'مؤكد': nextStatus = 'جاري التجهيز'; break;
      case 'جاري التجهيز': nextStatus = 'في الطريق'; break;
      case 'في الطريق': nextStatus = 'تم التسليم'; break;
    }
    if (nextStatus != currentStatus) await updateOrderStatus(orderId, nextStatus);
  }

  Future<void> sendCloudNotification(NotificationEntity n) async => await _cloud.sendNotification(n);

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  void markAllNotificationsAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // ─── تحليلات وتقارير المدير الشاملة ───
  double get totalPlatformRevenue => orders.fold(0.0, (sum, o) => sum + o.total);
  int get totalPlatformOrders => orders.length;

  Map<String, double> get vendorSalesMap {
    Map<String, double> map = {};
    for (var o in orders) {
      map[o.vendorId] = (map[o.vendorId] ?? 0) + o.total;
    }
    return map;
  }

  Map<String, int> get topProductsMap {
    Map<String, int> map = {};
    for (var o in orders) {
      for (var it in o.items) {
        map[it.product.name] = (map[it.product.name] ?? 0) + it.qty;
      }
    }
    return map;
  }

  Map<String, double> get topClientsMap {
    Map<String, double> map = {};
    for (var o in orders) {
      map[o.clientName] = (map[o.clientName] ?? 0) + o.total;
    }
    return map;
  }

  // ─── تحليلات وتقارير المورد الخاصة ───
  double get vendorTotalSales => orders.fold(0.0, (sum, o) => sum + o.total);
  int get vendorOrdersCount => orders.length;

  Map<String, int> get vendorTopItems {
    Map<String, int> map = {};
    for (var o in orders) {
      for (var it in o.items) {
        map[it.product.name] = (map[it.product.name] ?? 0) + it.qty;
      }
    }
    return map;
  }

  Map<String, double> get vendorTopClients {
    Map<String, double> map = {};
    for (var o in orders) {
      map[o.clientName] = (map[o.clientName] ?? 0) + o.total;
    }
    return map;
  }
}

final appState = AppState();