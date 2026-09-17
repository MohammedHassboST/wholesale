import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

enum RealtimeStatus {
  connected,
  connecting,
  disconnected,
}

/// خدمة مركزية لإدارة التتبع اللحظي (Realtime Tracking) لجميع أقسام المنصة
/// تتابع حالة اتصال الـ WebSocket مع Supabase وتوفر إعادة الاتصال التلقائي
class RealtimeService {
  final SupabaseClient _client;
  final _statusCtrl = StreamController<RealtimeStatus>.broadcast();
  RealtimeStatus _currentStatus = RealtimeStatus.connecting;
  final Map<String, RealtimeChannel> _channels = {};
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  RealtimeService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client {
    _init();
  }

  RealtimeStatus get currentStatus => _currentStatus;
  Stream<RealtimeStatus> get statusStream => _statusCtrl.stream;
  bool get isConnected => _currentStatus == RealtimeStatus.connected;

  void _init() {
    try {
      // 1. مراقبة تغيرات حالة مقبس الـ Realtime باستخدام الأحداث المتاحة
      _client.realtime.onOpen(() => _setStatus(RealtimeStatus.connected));
      _client.realtime.onClose((_) {
        _setStatus(RealtimeStatus.disconnected);
        _scheduleReconnect();
      });
      _client.realtime.onError((e) {
        debugPrint('📡 [RealtimeService] خطأ في مقبس Realtime: $e');
        _setStatus(RealtimeStatus.disconnected);
        _scheduleReconnect();
      });
    } catch (e) {
      debugPrint('⚠️ [RealtimeService] خطأ في مراقبة مقبس Realtime: $e');
    }

    // 2. اشتراك في قناة نبض للتحقق من الاستجابة اللحظية للسيرفر
    _subscribeTrackerChannel();

    // 3. فحص دوري للاتصال كل 12 ثانية لتأكيد سلامة المزامنة
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      try {
        final connected = _client.realtime.isConnected;
        if (connected && _currentStatus != RealtimeStatus.connected) {
          _setStatus(RealtimeStatus.connected);
        } else if (!connected && _currentStatus == RealtimeStatus.connected) {
          _setStatus(RealtimeStatus.disconnected);
          _scheduleReconnect();
        }
      } catch (_) {}
    });
  }

  void _subscribeTrackerChannel() {
    try {
      final ch = _client.channel('waffart_platform_realtime');
      ch.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _setStatus(RealtimeStatus.connected);
        } else if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          _setStatus(RealtimeStatus.disconnected);
          _scheduleReconnect();
        }
      });
      _channels['waffart_platform_realtime'] = ch;
    } catch (e) {
      debugPrint('⚠️ [RealtimeService] تعذر الاشتراك في قناة المنصة: $e');
    }
  }

  void _setStatus(RealtimeStatus s) {
    if (_currentStatus != s) {
      _currentStatus = s;
      _statusCtrl.add(s);
      debugPrint('📡 [RealtimeService] تغيرت حالة التتبع اللحظي: $s');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      debugPrint('🔄 [RealtimeService] محاولة إعادة الاتصال التلقائي...');
      reconnect();
    });
  }

  /// إعادة الاتصال يدوياً أو بعد انقطاع
  void reconnect() {
    try {
      _setStatus(RealtimeStatus.connecting);
      // ignore: invalid_use_of_internal_member
      _client.realtime.connect();
    } catch (e) {
      debugPrint('⚠️ [RealtimeService] خطأ أثناء محاولة الاتصال: $e');
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    for (final c in _channels.values) {
      _client.removeChannel(c);
    }
    _channels.clear();
    _statusCtrl.close();
  }
}
