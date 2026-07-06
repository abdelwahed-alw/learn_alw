import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'app_state_model.dart';
import 'constants.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isVisible = true);
    });

    Future.delayed(const Duration(milliseconds: 2500), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final model = context.read<AppStateModel>();
    if (!model.hasSelectedTheme) {
      _showThemeSelector();
      return;
    }
    final destination = model.isOnboardingDone
        ? const AppShell()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: kPremiumCurve),
          child: child,
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDark = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? kColorSurface : kColorSurfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'chooseAppearance'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? kColorText : kColorTextLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isDark = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: !isDark
                                  ? kColorPrimary.withValues(alpha: 0.15)
                                  : (isDark
                                      ? kColorCard
                                      : kColorCardLight),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !isDark
                                    ? kColorPrimary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.light_mode_rounded,
                                  size: 36,
                                  color: !isDark
                                      ? kColorPrimary
                                      : kColorTextMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'lightMode'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !isDark
                                        ? kColorPrimary
                                        : kColorTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isDark = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? kColorPrimary.withValues(alpha: 0.15)
                                  : (isDark
                                      ? kColorCard
                                      : kColorCardLight),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? kColorPrimary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.dark_mode_rounded,
                                  size: 36,
                                  color: isDark
                                      ? kColorPrimary
                                      : kColorTextMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'darkMode'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? kColorPrimary
                                        : kColorTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final model = context.read<AppStateModel>();
                      await model.completeThemeSelection(isDark);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      final destination = model.isOnboardingDone
                          ? const AppShell()
                          : const OnboardingScreen();
                      Navigator.of(ctx).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => destination,
                          transitionDuration: const Duration(milliseconds: 500),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(
                            opacity: CurvedAnimation(
                                parent: anim, curve: kPremiumCurve),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'continue'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: _isVisible ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: AnimatedScale(
                    scale: _isVisible ? 1.0 : 0.6,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutBack,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sa',
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Learn.',
                              style: const TextStyle(color: kColorPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedOpacity(
                  opacity: _isVisible ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                'By ABDELWAHED',
                style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.7),
                  fontSize: 13,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
