import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'home_tab.dart';
import 'exercises_tab.dart';
import 'progress_tab.dart';
import 'profile_tab.dart';
import 'ui_strings.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            onNavigateExercises: () => setState(() => _currentIndex = 1),
          ),
          const ExercisesTab(),
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
    final items = [
      (Icons.home_rounded, tr(context, 'home')),
      (Icons.menu_book_rounded, tr(context, 'exercises')),
      (Icons.bar_chart_rounded, tr(context, 'progress')),
      (Icons.person_rounded, tr(context, 'profile')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kColorSurface,
        border: Border(
          top: BorderSide(color: kColorBorder.withValues(alpha: 0.5)),
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
                            : kColorAccent.withValues(alpha: 0.6),
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
                              : kColorAccent.withValues(alpha: 0.6),
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
