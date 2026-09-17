import '../../data/datasources/notification_service.dart';
import '../../presentation/state/app_state.dart';

/// Watches [appState] and fires a local push notification for every *new*
/// cloud notification targeted at the current user.
///
/// Notes:
/// - [AppState] already filters the stream (global + my phone/id only),
///   so everything in [AppState.notifications] is meant for me.
/// - The first sync is primed silently so old history doesn't spam;
///   only arrivals *while the app runs* trigger a push.
/// - Unread badges are driven separately by [AppState.unreadNotificationsCount].
class NotificationWatcher {
  final Set<String> _seen = {};
  bool _primed = false;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    appState.addListener(_onAppState);
  }

  void _onAppState() {
    final current = appState.notifications;
    if (!_primed) {
      _seen.addAll(current.map((n) => n.id));
      _primed = true;
      return;
    }
    for (final n in current) {
      if (_seen.add(n.id)) {
        NotificationService().show(
          title: n.title,
          body: n.body,
          payload: n.payload,
        );
      }
    }
    if (_seen.length > 1000) {
      final alive = current.map((n) => n.id).toSet();
      _seen.retainAll(alive);
    }
  }
}

final notificationWatcher = NotificationWatcher();
