import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/notification_watcher.dart';
import 'data/datasources/notification_service.dart';
import 'presentation/state/app_state.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/screens/admin/super_admin_dashboard.dart';
import 'presentation/screens/vendor/vendor_dashboard.dart';
import 'presentation/screens/retailer/retailer_shell.dart';
import 'core/constants/constants.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  await initDI();

  // Local push for realtime cloud notifications (client / vendor / admin).
  try {
    await NotificationService().init();
    notificationWatcher.attach();
  } catch (e) {
    debugPrint('Notifications init notice: $e');
  }

  runApp(const Waffart());
}

class Waffart extends StatelessWidget {
  const Waffart({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isArabic = appState.isRtl;

        return MaterialApp(
          title: 'منصة وُفّرت - Waffart B2B',
          debugShowCheckedModeBanner: false,
          locale: Locale(appState.currentLocale),
          supportedLocales: const [
            Locale('ar', 'EG'),
            Locale('ar'),
            Locale('en', 'US'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: AppColors.brand,
            scaffoldBackgroundColor: AppColors.paper,
            fontFamily: isArabic ? 'Cairo' : 'Roboto',
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
          ),
          home: _getHomeRoute(),
        );
      },
    );
  }

  Widget _getHomeRoute() {
    final user = appState.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    if (user.role == 'super_admin') {
      return const SuperAdminDashboard();
    } else if (user.role == 'vendor') {
      return const VendorDashboard();
    } else {
      return const RetailerShell();
    }
  }
}