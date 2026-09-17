import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection_container.dart';
import 'presentation/state/app_state.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/screens/admin/super_admin_dashboard.dart';
import 'presentation/screens/vendor/vendor_dashboard.dart';
import 'presentation/screens/retailer/retailer_shell.dart';
import 'core/constants/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase
  try {
    await Supabase.initialize(
      url: 'https://gkjgwbwmucotqftbhgyn.supabase.co',
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdramd3YndtdWNvdHFmdGJoZ3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1OTg3NjgsImV4cCI6MjEwNTE3NDc2OH0.8POIXCLUtOch0W4frnUbC29dbsbSQb_Gud3aRcd6QYA',
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  await initDI();
  runApp(const Waffart());
}

class Waffart extends StatelessWidget {
  const Waffart({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'منصة وُفّرت - Waffart B2B',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Directionality(
              textDirection: appState.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          theme: ThemeData(
            primaryColor: AppColors.brand,
            scaffoldBackgroundColor: AppColors.paper,
            fontFamily: 'Cairo',
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