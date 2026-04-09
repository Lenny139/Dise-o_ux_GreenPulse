import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'core/api_client.dart';
import 'services/auth_service.dart';
import 'views/activity_view.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';
import 'views/profile_view.dart';
import 'views/projects_view.dart';
import 'views/settings_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.primary,
          secondary: AppPalette.secondary,
          surface: AppPalette.surface,
          onPrimary: Colors.white,
          onSurface: AppPalette.textPrimary,
        );

    return MaterialApp(
      title: 'GreenPulse UX',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppPalette.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.surface,
          foregroundColor: AppPalette.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
      ),
      routes: {
        '/login': (_) => const AuthScreen(),
        '/home': (_) => const HomePage(),
      },
      home: const _AuthGate(),
    );
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _authService = AuthService();
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    ApiClient.navigatorKey = _navigatorKey;
    _sessionFuture = _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomePage();
        }

        return const AuthScreen();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<String> _navLabels = [
    'Inicio',
    'Proyectos',
    'Actividad',
    'Perfil',
    'Ajustes',
  ];

  static const List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.folder_open_rounded,
    Icons.insights_rounded,
    Icons.person_rounded,
    Icons.settings_rounded,
  ];

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeDashboardScreen();
      case 1:
        return const ProjectsScreen();
      case 2:
        return const ActivityScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const HomeDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GreenPulse',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: const Color(0xFFDCEFE5),
        destinations: List.generate(
          _navLabels.length,
          (index) => NavigationDestination(
            icon: Icon(_navIcons[index]),
            label: _navLabels[index],
          ),
        ),
      ),
    );
  }
}
