import 'package:flutter/material.dart';
import 'store_page.dart';
import 'orders_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

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
          body: IndexedStack(
            index: index,
            children: const [
              StorePage(),
              OrdersPage(),
              NotificationsPage(),
              ProfilePage(),
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
              const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'سوق الجملة'),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'طلباتي'),
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
                label: 'الإشعارات',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}