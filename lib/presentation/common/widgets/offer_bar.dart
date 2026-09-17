import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/l10n/app_strings.dart';

class OfferBar extends StatelessWidget {
  final int remaining;
  final int total;
  const OfferBar({super.key, required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final urgent = pct <= 0.2 && remaining > 0;
    final finished = remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerRight,
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: finished
                        ? [Colors.grey, Colors.grey.shade600]
                        : urgent
                        ? [AppColors.danger, const Color(0xFFEF4444)]
                        : [AppColors.amber, const Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: (finished ? Colors.grey : urgent ? AppColors.danger : AppColors.amber).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (finished)
              const Icon(Icons.check_circle, size: 14, color: Colors.grey)
            else if (urgent)
              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger)
            else
              const Icon(Icons.local_fire_department, size: 14, color: AppColors.amber),
            const SizedBox(width: 4),
            Text(
              finished
                  ? tr('نفذت الكمية')
                  : urgent
                  ? trArgs('متبقي {r} فقط! من أصل {t}', {'r': remaining, 't': total})
                  : trArgs('متبقي {r} من {t}', {'r': remaining, 't': total}),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: finished ? Colors.grey.shade600 : urgent ? AppColors.danger : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}