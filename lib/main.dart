import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/auth_service_fixed.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/score_table_screen.dart';
import 'screens/user_task_management_screen.dart';
import 'screens/captain_task_management_screen.dart';
import 'screens/admin_task_management_screen.dart';
import 'screens/admin_manage_users_screen.dart';
import 'screens/role_management_screen.dart';
import 'screens/my_team_screen.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', 'TR'), // Türkçe
              Locale('en', 'US'), // İngilizce (Varsayılan)
            ],
            locale: const Locale(
                'tr', 'TR'), // Uygulamanın varsayılan dilini Türkçe yap
            title: 'Ekip Yönetim Sistemi',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/setup': (context) => const SetupScreen(),
              '/score_table': (context) => const ScoreTableScreen(),
              '/user_task_management': (context) =>
              const UserTaskManagementScreen(),
              '/captain_task_management': (context) =>
              const CaptainTaskManagementScreen(),
              '/admin_task_management': (context) =>
              const AdminTaskManagementScreen(),
              '/admin_manage_users': (context) =>
              const AdminManageUsersScreen(),
              '/role_management': (context) => const RoleManagementScreen(),
              '/my_team': (context) => const MyTeamScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
