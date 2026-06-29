import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';

class LearnAlwApp extends StatelessWidget {
  const LearnAlwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salearn',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: Consumer<AppStateModel>(
        builder: (context, model, _) {
          return model.isOnboardingDone
              ? const HomeScreen()
              : const OnboardingScreen();
        },
      ),
    );
  }
}
