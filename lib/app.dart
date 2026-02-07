import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/game_flow_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/stats_screen.dart';

/// Main app widget with routing and theming
class StocksApp extends StatelessWidget {
  const StocksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Stocks',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.darkMode == null
              ? ThemeMode.system
              : (settings.darkMode! ? ThemeMode.dark : ThemeMode.light),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/game': (context) => const GameFlowScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/rules': (context) => const RulesScreen(),
            '/stats': (context) => const StatsScreen(),
          },
        );
      },
    );
  }
}
