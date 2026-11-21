
import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_management_screen.dart';
import 'screens/main_shell.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  runApp(const MyApp());
}

typedef MyApp = HerbaCatApp;

class HerbaCatApp extends StatefulWidget {
  const HerbaCatApp({super.key});

  @override
  State<HerbaCatApp> createState() => _HerbaCatAppState();
}

class _HerbaCatAppState extends State<HerbaCatApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerbaCat - Catanduanes Ethnobotanical Archive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginScreen(appState: _appState),
      routes: {
        '/admin': (context) {
          // Protected /admin route: redirects non-admin users to MainShell
          if (_appState.currentUser.isAdmin) {
            return AdminManagementScreen(appState: _appState);
          } else {
            return MainShell(appState: _appState);
          }
        },
      },
    );
  }
}
