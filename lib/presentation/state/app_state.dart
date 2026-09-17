import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../domain/repositories/i_cloud_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../core/l10n/app_strings.dart';

class CartItem {
  final ProductEntity product;
  int qty;
  double unitPrice; 

  CartItem({required this.product, required this.qty, required this.unitPrice});
}

class AppState extends ChangeNotifier {
  ICloudRepository get _cloud => GetIt.I<ICloudRepository>();

  UserEntity? currentUser;
  List<ProductEntity> products = [];
  List<ProductEntity> offers = []; // New list for offers
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
  StreamSubscription? _profileSub;

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
    // We delay this to ensure initDI and Supabase are ready
    Future.microtask(() => _loadSession());
  }

  bool get isRtl => currentLocale == 'ar';

  void toggleLocale() {
    currentLocale = currentLocale == 'ar' ? 'en' : 'ar';
    AppLocale.code = currentLocale;
    SharedPreferences.getInstance().then((p) => p.setString('locale', currentLocale));
    notifyListeners();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentLocale = prefs.getString('locale') ?? 'ar';
    AppLocale.code = currentLocale;
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
    // Merge with the stored profile so login never clobbers server-side state
    // (e.g. a vendor's 'pending' status must not be overwritten with 'active').
    UserEntity effective = user;
    bool isFirstRegistration = true;
    try {
      final existing = await _cloud.getUserByPhone(user.phone);
      if (existing != null) {
        isFirstRegistration = false;
        effective = UserEntity(
          id: existing.id.isNotEmpty ? existing.id : user.id,
          name: user.name.isNotEmpty ? user.name : existing.name,
          phone: user.phone,
          role: existing.role.isNotEmpty ? existing.role : user.role,
          shopName: user.shopName ?? existing.shopName,
          address: user.address ?? existing.address,
          businessActivity: user.businessActivity ?? existing.businessActivity,
          status: existing.status,
          createdAt: existing.createdAt,
        );
      }
    } catch (_) {
      // Offline / table missing → fall back to the supplied user.
    }

    currentUser = effective;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', effective.id);
    await prefs.setString('userName', effective.name);
    await prefs.setString('userPhone', effective.phone);
    await prefs.setString('userRole', effective.role);
    await prefs.setString('userStatus', effective.status);
    if (effective.shopName != null) await prefs.setString('shopName', effective.shopName!);
    if (effective.address != null) await prefs.setString('userAddress', effective.address!);
    if (effective.businessActivity != null) await prefs.setString('businessActivity', effective.businessActivity!);

    await _cloud.saveUser(effective);

    // Brand-new pending vendor → alert the platform admin in real time.
    if (isFirstRegistration && effective.role == 'vendor' && effective.status == 'pending') {
      try {
        await _cloud.sendNotification(NotificationEntity(
          id: '',
          title: '🆕 طلب انضمام مورد جديد',
          body: '${effective.name} (${effective.phone}) — ${effective.businessActivity ?? effective.shopName ?? 'نشاط عام'} بانتظار المراجعة والاعتماد.',
          createdAt: DateTime.now(),
          targetPhone: 'super_admin_1',
          payload: 'vendor:${effective.id}',
        ));
      } catch (_) {}
    }

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
    _profileSub?.cancel();

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
      _refreshCartPrices(); // تحديث أسعار السلة بناءً على أحدث البيانات
      notifyListeners();
    });
  }

  void _initCloudSync() {
    _productsSub?.cancel();
    _ordersSub?.cancel();
    _vendorsSub?.cancel();
    _categoriesSub?.cancel();
    _notificationsSub?.cancel();
    _profileSub?.cancel();

    if (currentUser == null) return;

    _categoriesSub = _cloud.getCategoriesStream().listen((list) {
      categories = list;
      notifyListeners();
    }, onError: (e) => debugPrint('❌ Error Categories: $e'));

    _notificationsSub = _cloud.getNotificationsStream().listen((list) {
      // Global notifications (no target) + ones targeted at me by phone or id.
      notifications = list.where((n) {
        final t = n.targetPhone;
        if (t == null || t.isEmpty) return true;
        return t == currentUser?.phone || t == currentUser?.id;
      }).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('❌ Error Notifications: $e'));

    // ==========================================
    // منطق المورد (Vendor)
    // ==========================================
    if (currentUser!.role == 'vendor') {
      debugPrint('👤 تسجيل دخول كمورد. الـ ID: ${currentUser!.id}');
      _productsSub = _cloud.getVendorProductsStream(currentUser!.id).listen((list) {
        debugPrint('✅ تم تحديث واجهة المورد. عدد المنتجات: ${list.length}');
        products = list;
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ خطأ في جلب منتجات المورد: $error');
      });
      _ordersSub = _cloud.getVendorOrdersStream(currentUser!.id).listen((list) {
        orders = list;
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ خطأ في جلب طلبات المورد: $error');
      });
      // Live profile sync: admin approval / rejection / suspension
      // reflects instantly without re-login.
      _profileSub = _cloud.getMyProfileStream(currentUser!.id).listen((remote) {
        if (remote == null || currentUser == null) return;
        if (remote.status != currentUser!.status) {
          currentUser = UserEntity(
            id: currentUser!.id,
            name: currentUser!.name,
            phone: currentUser!.phone,
            role: currentUser!.role,
            shopName: remote.shopName ?? currentUser!.shopName,
            address: remote.address ?? currentUser!.address,
            businessActivity: remote.businessActivity ?? currentUser!.businessActivity,
            status: remote.status,
            createdAt: currentUser!.createdAt,
          );
          SharedPreferences.getInstance().then((p) => p.setString('userStatus', remote.status));
          notifyListeners();
        }
      }, onError: (e) => debugPrint('❌ Error ProfileSync: $e'));
    }
    // ==========================================
    // منطق العميل (Customer)
    // ==========================================
    else if (currentUser!.role == 'customer') {
      debugPrint('👤 تسجيل دخول كعميل. جلب جميع المنتجات...');

      _productsSub = _cloud.getProductsStream().listen((list) {
        debugPrint('✅ تم تحديث واجهة العميل. إجمالي المنتجات: ${list.length}');

        // Keep offers inside `products` so the store grid shows them
        // (ProductCard already renders offer pricing/progress); `offers`
        // stays as the offers-only subset for offer-specific UI.
        products = list;
        offers = list.where((p) => p.isOffer == true).toList();

        _refreshCartPrices(); // مزامنة أسعار السلة
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ خطأ في جلب منتجات العميل: $error');
      });
      _ordersSub = _cloud.getClientOrdersStream(currentUser!.id).listen((list) {
        orders = list;
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ خطأ في جلب طلبات العميل: $error');
      });
    }
    // ==========================================
    // منطق المدير (Super Admin)
    // ==========================================
    else if (currentUser!.role == 'super_admin') {
      _productsSub = _cloud.getProductsStream().listen((list) {
        products = list;
        notifyListeners();
      }, onError: (e) => debugPrint('❌ Error Admin Products: $e'));
      _ordersSub = _cloud.getOrdersStream().listen((list) {
        orders = list;
        notifyListeners();
      }, onError: (e) => debugPrint('❌ Error Admin Orders: $e'));
      _vendorsSub = _cloud.getVendorsStream().listen((list) {
        vendors = list;
        notifyListeners();
      }, onError: (e) => debugPrint('❌ Error Admin Vendors: $e'));
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
    final existing = cart.where((c) => c.product.id == product.id).firstOrNull;
    if (existing != null) {
      existing.qty += product.minOrderQty;
      existing.unitPrice = existing.product.priceForQty(existing.qty);
    } else {
      final qty = product.minOrderQty;
      cart.add(CartItem(product: product, qty: qty, unitPrice: product.priceForQty(qty)));
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
        item.unitPrice = item.product.priceForQty(newQty);
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  // Add the missing deleteProfile method for vendor deletion
  Future<void> deleteProfile(String vendorId) async {
    await Supabase.instance.client.from('profiles').delete().eq('id', vendorId);
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

          // Low-stock alerts are emitted server-side by the atomic checkout
          // RPC (single source of truth) — no client-side guessing here.
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
      }

      // حفظ ذري واحد عبر RPC: يتحقق من المخزون ويخصمه ويسجّل الطلبات
      // ويولّد إشعارات المورد + تنبيهات قرب النفاذ — كل ذلك server-side
      // في ترانزاكشن واحدة (مستحيل يحصل overselling).
      final placed = await _cloud.placeOrdersWithAtomicStockCheck(newOrders);
      if (!placed) {
        // إعادة جلب المنتجات لتحديث الحالة اللحظية (تحديث الكميات المتاحة)
        _cloud.getProductsStream().first.then((list) {
          products = list;
          notifyListeners();
        });
        return false;
      }

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

  void _refreshCartPrices() {
    if (cart.isEmpty) return;
    for (var item in cart) {
      final p = products.firstWhere((pr) => pr.id == item.product.id, orElse: () => item.product);
      // تحديث السعر للوحدة بناءً على الحالة الحالية للمنتج (عرض أو سعر متدرج)
      item.unitPrice = p.priceForQty(item.qty);
    }
  }

  // ─── إدارة الأصناف والعروض ───
  Future<void> addProduct(ProductEntity product) async {
    if (currentUser == null) return;
    await _cloud.addProduct(currentUser!.id, product);

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

  Future<void> deleteProduct(String id) async {
    if (currentUser == null) return;
    await _cloud.deleteProduct(currentUser!.id, id);
  }

  void updateProduct(ProductEntity updatedProduct) {
    if (currentUser == null) return;
    _cloud.updateProduct(currentUser!.id, updatedProduct.id, updatedProduct.toMap());
  }

  void updateProductStock(String productId, int newStock) {
    if (currentUser == null) return;
    _cloud.updateProduct(currentUser!.id, productId, {'offer_remaining_qty': newStock});
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
    if (currentUser == null) return;
    if (!categories.contains(cat)) {
      await _cloud.addCategory(currentUser!.id, cat);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String cat) async {
    if (currentUser == null || cat == 'الكل') return;
    await _cloud.deleteCategory(currentUser!.id, cat);
    notifyListeners();
  }

  // ─── تحكم المدير في الموردين ───
  Future<void> updateVendorStatus(String vendorId, String status) async {
    if (currentUser == null) return;
    await _cloud.updateVendorStatus(currentUser!.id, vendorId, status);
    final idx = vendors.indexWhere((v) => v.id == vendorId);
    if (idx != -1) {
      final v = vendors[idx];
      vendors[idx] = UserEntity(
        id: v.id, name: v.name, phone: v.phone, role: v.role, shopName: v.shopName,
        address: v.address, businessActivity: v.businessActivity, status: status,
      );
      notifyListeners();
    }

    // Real-time status-change alert for the vendor (approval / rejection / suspension).
    try {
      final msg = status == 'active'
          ? 'تم قبول وتفعيل حسابك في منصة وُفّرت — يمكنك الآن إضافة أصنافك واستقبال الطلبات.'
          : status == 'rejected'
              ? 'تم رفض طلب انضمامك من قبل مدير المنصة. تواصل مع الإدارة للمزيد من التفاصيل.'
              : status == 'inactive'
                  ? 'قام مدير المنصة بإيقاف حسابك مؤقتاً. تواصل مع الإدارة لمراجعة الموقف.'
                  : 'تم تحديث حالة حسابك إلى: $status';
      await _cloud.sendNotification(NotificationEntity(
        id: '',
        title: status == 'active' ? '🎉 تم تفعيل حسابك!' : '🔔 تحديث حالة حسابك',
        body: msg,
        createdAt: DateTime.now(),
        targetPhone: vendorId,
        payload: 'account:$vendorId',
      ));
    } catch (_) {}
  }

  Future<void> deleteVendor(String vendorId) async {
    if (currentUser == null) return;
    await _cloud.deleteVendor(currentUser!.id, vendorId);
    vendors.removeWhere((v) => v.id == vendorId);
    notifyListeners();
  }

  Future<void> addVendorByAdmin(UserEntity vendor) async {
    if (currentUser == null) return;
    await _cloud.saveUser(vendor); // Replaced saveVendorByAdmin with existing saveUser
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

  /// Admin edits an order: item quantities (0 removes the line; offer stock
  /// reconciled atomically server-side) + client info. Client notified once.
  Future<void> editOrder(
    String orderId, {
    Map<String, int>? itemsQty,
    String? clientName,
    String? clientPhone,
    String? clientAddress,
  }) async {
    if (itemsQty != null) {
      for (final e in itemsQty.entries) {
        await _cloud.updateOrderItem(orderId, e.key, e.value);
      }
    }
    if (clientName != null || clientPhone != null || clientAddress != null) {
      await _cloud.updateOrderInfo(orderId, name: clientName, phone: clientPhone, address: clientAddress);
    }
    final order = orders.where((o) => o.id == orderId).firstOrNull;
    await _cloud.sendNotification(NotificationEntity(
      id: '',
      title: '✏️ تم تعديل طلبك من قبل الإدارة',
      body: 'طلبك رقم #$orderId تم تعديله. راجع قائمة طلباتك للتفاصيل.',
      createdAt: DateTime.now(),
      targetPhone: order?.clientPhone,
      payload: 'order:$orderId',
    ));
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