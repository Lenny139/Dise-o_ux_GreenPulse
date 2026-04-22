import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_palette.dart';
import 'backup/database/local_database.dart';
import 'core/api_client.dart';
import 'core/app_language_controller.dart';
import 'core/app_theme_controller.dart';
import 'core/app_text.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'views/activity_view.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';
import 'views/notifications_view.dart';
import 'views/opciones_view.dart';
import 'views/plantas_view.dart';
import 'views/projects_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.database; // inicializa SQLite
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageController.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeController.themeMode,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'GreenPulse',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigatorKey,
              locale: locale,
              themeMode: themeMode,
              builder: (context, child) {
                if (child == null) return const SizedBox.shrink();

                final screenWidth = MediaQuery.sizeOf(context).width;
                final shouldUseAppViewport = kIsWeb || screenWidth >= 900;

                if (!shouldUseAppViewport) return child;

                return ColoredBox(
                  color: AppPalette.viewportBackgroundOf(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: child,
                    ),
                  ),
                );
              },
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              routes: {
                '/login': (_) => const AuthScreen(),
                '/home': (_) => const HomePage(),
              },
              home: const _AuthGate(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
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
        return snapshot.data == true ? const HomePage() : const AuthScreen();
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
  final _settingsService = SettingsService();

  static const List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.folder_open_rounded,
    Icons.insights_rounded,
    Icons.tune_rounded,
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
        return const OpcionesScreen();
      default:
        return const HomeDashboardScreen();
    }
  }

  List<String> get _navLabels => [
        AppText.t(es: 'Inicio', en: 'Home'),
        AppText.t(es: 'Proyectos', en: 'Projects'),
        AppText.t(es: 'Actividad', en: 'Activity'),
        AppText.t(es: 'Opciones', en: 'Options'),
      ];

  @override
  void initState() {
    super.initState();
    _syncThemeWithBackend();
  }

  Future<void> _syncThemeWithBackend() async {
    try {
      final ajustes = await _settingsService.getAjustes();
      final tema = ajustes['tema']?.toString() ?? 'Claro (GreenPulse)';
      final idioma = ajustes['idioma']?.toString() ?? 'Español';
      AppLanguageController.applyLanguageLabel(idioma);
      AppThemeController.applyThemeLabel(tema);
    } catch (_) {}
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlantasScreen()),
            ),
            icon: const Icon(Icons.yard_rounded),
            tooltip: 'Catálogo de plantas',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        indicatorColor: AppPalette.navIndicatorOf(context),
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
