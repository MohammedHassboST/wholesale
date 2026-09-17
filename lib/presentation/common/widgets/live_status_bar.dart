import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../data/datasources/realtime_service.dart';
import '../../../core/l10n/app_strings.dart';

/// شريط مؤشر التتبع اللحظي (Live Status Bar)
/// يعرض حالة اتصال المقبس السحابي (Realtime WebSockets) في المنصة بدعم كامل للـ RTL
class LiveStatusBar extends StatelessWidget {
  final bool showWhenConnected;
  const LiveStatusBar({super.key, this.showWhenConnected = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final status = appState.realtimeStatus;

        // في حال كان متصلاً والوضع المصغر مطلوب
        if (status == RealtimeStatus.connected && !showWhenConnected) {
          return const SizedBox.shrink();
        }

        final Color statusColor;
        final Color bgColor;
        final String statusLabel;
        final IconData? iconData;
        final bool showRetry;

        switch (status) {
          case RealtimeStatus.connected:
            statusColor = const Color(0xFF15803D); // Green 700
            bgColor = const Color(0xFFDCFCE7); // Green 100
            statusLabel = tr('متصل لحظياً بالمنصة (مزامنة فورية)');
            iconData = null;
            showRetry = false;
            break;
          case RealtimeStatus.connecting:
            statusColor = const Color(0xFFB45309); // Amber 700
            bgColor = const Color(0xFFFEF3C7); // Amber 100
            statusLabel = tr('جارٍ الاتصال والمزامنة اللحظية...');
            iconData = Icons.sync;
            showRetry = false;
            break;
          case RealtimeStatus.disconnected:
            statusColor = const Color(0xFFB91C1C); // Red 700
            bgColor = const Color(0xFFFEE2E2); // Red 100
            statusLabel = tr('غير متصل بالخادم — انقطاع الاتصال');
            iconData = Icons.wifi_off_rounded;
            showRetry = true;
            break;
        }

        return Directionality(
          textDirection: appState.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (status == RealtimeStatus.connected)
                  const _LivePulseDot(color: Color(0xFF16A34A))
                else if (iconData != null)
                  Icon(iconData, size: 14, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status == RealtimeStatus.connected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 11, color: Color(0xFF15803D)),
                        const SizedBox(width: 2),
                        Text(
                          tr('مباشر'),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (showRetry)
                  InkWell(
                    onTap: () => appState.reconnectRealtime(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            tr('إعادة الاتصال'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// نقطة نبض متحركة للتعبير عن الاتصال المباشر اللحظي
class _LivePulseDot extends StatefulWidget {
  final Color color;
  const _LivePulseDot({required this.color});

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // موجة النبض الخارجية
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: _opacityAnimation.value),
                ),
              ),
            ),
          ),
          // النقطة المركزية الثابتة
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
