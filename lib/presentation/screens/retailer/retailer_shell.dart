import 'package:flutter/material.dart';
import 'store_page.dart';
import 'orders_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import '../../state/app_state.dart';
import '../../common/widgets/live_status_bar.dart';
import '../../../core/constants/constants.dart';
import '../../../core/l10n/app_strings.dart';

class RetailerShell extends StatefulWidget {
  const RetailerShell({super.key});

  @override
  State<RetailerShell> createState() => _RetailerShellState();
}

class _RetailerShellState extends State<RetailerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              const LiveStatusBar(),
              Expanded(
                child: IndexedStack(
                  index: index,
                  children: const [
                    StorePage(),
                    OrdersPage(),
                    NotificationsPage(),
                    ProfilePage(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            selectedItemColor: AppColors.brand,
            unselectedItemColor: AppColors.inkSoft,
            backgroundColor: AppColors.card,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), activeIcon: const Icon(Icons.storefront), label: tr('سوق الجملة')),
              BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: tr('طلباتي')),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (appState.unreadNotificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          child: Text(
                            '${appState.unreadNotificationsCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.notifications),
                label: tr('الإشعارات'),
              ),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: tr('حسابي')),
            ],
          ),
        );
      },
    );
  }
}