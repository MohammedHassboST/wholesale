import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/notification_entity.dart';
import '../../presentation/state/app_state.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _notifications.initialize(settings: initSettings);

    // ✅ طلب الإذن لـ Android 13+ و iOS
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notifications
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wholesale_channel',
      'سوق الجملة',
      channelDescription: 'إشعارات الطلبات والعروض',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31), // unique-ish 32-bit id (millisecond 0-999 collides and overwrites)
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ─── إرسال إشعارات سحابية (للمورد) ───
  Future<void> sendGlobalOfferNotification(String name, String price) async {
    final n = NotificationEntity(
      id: '', // سيتم توليده في Firestore
      title: '🎉 عرض جديد متاح!',
      body: 'احصل على "$name" بـ $price لفترة محدودة!',
      createdAt: DateTime.now(),
      payload: 'offer',
    );
    await appState.sendCloudNotification(n);
  }

  Future<void> sendGlobalNotification(String title, String body, {String? payload}) async {
    final n = NotificationEntity(
      id: '',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      payload: payload,
    );
    await appState.sendCloudNotification(n);
  }

  Future<void> sendOrderUpdateNotification(String phone, String orderId, String status) async {
    final n = NotificationEntity(
      id: '',
      title: 'تحديث حالة الطلب',
      body: 'طلبك #$orderId الآن: $status',
      createdAt: DateTime.now(),
      targetPhone: phone,
      payload: 'order:$orderId',
    );
    await appState.sendCloudNotification(n);
  }

  // ─── إشعارات جاهزة ───
  Future<void> orderConfirmed(String orderId) async {
    await show(
      title: '✓ تم تأكيد طلبك',
      body: 'طلبك #$orderId تم تأكيده بنجاح. الدفع كاش عند الاستلام.',
      payload: 'order:$orderId',
    );
  }

  Future<void> orderStatusChanged(String orderId, String newStatus) async {
    await show(
      title: 'تحديث حالة الطلب',
      body: 'طلبك #$orderId الآن: $newStatus',
      payload: 'order:$orderId',
    );
  }

  Future<void> newOffer(String productName, String price) async {
    await show(
      title: '🎉 عرض جديد متاح!',
      body: 'احصل على "$productName" بـ $price لفترة محدودة!',
      payload: 'offer',
    );
  }
}