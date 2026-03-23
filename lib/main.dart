// lib/main.dart
// App entry point for Salearn.
// Bootstraps SharedPreferences and the Provider tree, then launches the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'home_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before calling native code.
  WidgetsFlutterBinding.ensureInitialized();

  // Load SharedPreferences once at startup.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // Provide AppStateModel at the root — accessible throughout the widget tree.
    ChangeNotifierProvider<AppStateModel>(
      create: (_) {
        final model = AppStateModel(prefs);
        // Eagerly load persisted settings so the first build has real data.
        model.loadFromPrefs();
        return model;
      },
      child: const LearnAlwApp(),
    ),
  );
}

// ─── Root application widget ───────────────────────────────────────────────────

class LearnAlwApp extends StatelessWidget {
  const LearnAlwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salearn',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomeScreen(),
    );
  }

  // ── Dark theme (Premium Redesign) ───────────────────────────────────────────
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kColorBackground,
      colorScheme: const ColorScheme.dark(
        primary: kColorPrimary,
        secondary: kColorAccent,
        surface: kColorSurface,
        error: kColorError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: kColorText,
        onError: Colors.white,
      ),
      textTheme: buildPremiumTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Glassmorphism base
        foregroundColor: kColorText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle:
            buildPremiumTextTheme().titleLarge?.copyWith(fontSize: 22),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: kColorSurface,
        width: 320,
        elevation: 16,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kColorSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kColorPrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: kColorTextMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kColorPrimary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: kColorPrimary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: kColorSurface,
        contentTextStyle: buildPremiumTextTheme().bodyMedium,
        elevation: 12,
      ),
      dividerTheme: const DividerThemeData(color: kColorBorder, thickness: 1),
    );
  }

  // ── Light theme (minimal, not used by default) ─────────────────────────────
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kColorPrimary,
        brightness: Brightness.light,
      ),
    );
  }
}
