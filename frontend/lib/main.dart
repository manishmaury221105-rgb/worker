import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_endpoints.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/common/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load any saved custom base URL
  final savedUrl = await StorageService.getBaseUrl();
  if (savedUrl != null && savedUrl.isNotEmpty) {
    ApiEndpoints.setCustomBaseUrl(savedUrl);
  }
  
  runApp(const WorkerManagementApp());
}

class WorkerManagementApp extends StatelessWidget {
  const WorkerManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProv, localeProv, child) {
          return MaterialApp(
            title: 'श्री लक्ष्मीनारायण एल्युमिनियम वर्क्स',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.themeMode,
            locale: Locale(localeProv.currentLocale),
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('hi', 'IN'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
