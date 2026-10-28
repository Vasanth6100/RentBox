import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

import 'services/api_service.dart';
import 'services/app_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiService.instance.checkHealth();
  await AppStore.instance.syncWithBackend();
  runApp(const RentBoxApp());
}

class RentBoxApp extends StatelessWidget {
  const RentBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RentBox',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path.contains('admin')) {
          return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
        }
        switch (uri.path) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/explore':
            return MaterialPageRoute(builder: (_) => const ExploreScreen());
          case '/':
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
