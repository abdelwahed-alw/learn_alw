import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'home_tab.dart';
import 'exercises_tab.dart';
import 'progress_tab.dart';
import 'profile_tab.dart';
import 'quick_translation_sheet.dart';
import 'theme_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateModel>();
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: state.showTranslationFab
          ? FloatingActionButton(
              onPressed: () => showQuickTranslationSheet(context),
              backgroundColor: kColorPrimary,
              child: const Icon(Icons.translate_rounded, color: Colors.white),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
            HomeTab(
              onNavigateExercises: () => setState(() => _currentIndex = 1),
            ),
            ExercisesTab(
              onNavigateProfile: () => setState(() => _currentIndex = 3),
            ),
          ProgressTab(
            onNavigateExercises: () => setState(() => _currentIndex = 1),
          ),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final items = [
      (Icons.home_rounded, 'homeTab'.tr()),
      (Icons.menu_book_rounded, 'exercisesTab'.tr()),
      (Icons.bar_chart_rounded, 'progressTab'.tr()),
      (Icons.person_rounded, 'profileTab'.tr()),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _currentIndex = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? kColorPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 20,
                        color: isActive
                            ? kColorPrimary
                            : (isLight ? Colors.black54 : kColorAccent.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? kColorPrimary
                              : (isLight ? Colors.black54 : kColorAccent.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
