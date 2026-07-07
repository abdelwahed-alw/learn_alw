import 'package:easy_localization/easy_localization.dart' hide tr;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'ielts_screen.dart';
import 'beginner_screen.dart';
import 'categories_tab.dart';
import 'main_screen_body.dart';
import 'ui_strings.dart';

class ExercisesTab extends StatefulWidget {
  final VoidCallback? onNavigateProfile;
  const ExercisesTab({super.key, this.onNavigateProfile});

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(state),
              Expanded(
                child: IndexedStack(
                  index: state.appMode == AppMode.ielts
                      ? 1
                      : state.appMode == AppMode.beginner
                          ? 2
                          : state.appMode == AppMode.categories
                              ? 3
                              : 0,
                  children: [
                    MainScreenBody(onNavigateProfile: widget.onNavigateProfile),
                    const IeltsScreen(),
                    const BeginnerScreen(),
                    const CategoriesTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'exercisesTab'.tr(),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (state.appMode == AppMode.practice)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        levelEmoji(state.proficiencyLevel),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.proficiencyLevel,
                        style: const TextStyle(
                          color: kColorPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModeSelector(state),
          const SizedBox(height: 14),
          _buildTopicSelector(state),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildModeSelector(AppStateModel state) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cs = Theme.of(context).colorScheme;
    final modes = [
      (AppMode.practice, tr(context, 'practice'), Icons.chat_rounded),
      (AppMode.ielts, 'ielts'.tr(), Icons.assignment_rounded),
      (AppMode.beginner, tr(context, 'beginner'), Icons.auto_stories_rounded),
      (AppMode.categories, tr(context, 'categories'), Icons.grid_view_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: modes.map((m) {
          final isSelected = state.appMode == m.$1;
          return Expanded(
              child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              state.setAppMode(m.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kColorPrimary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    m.$3,
                    size: 14,
                    color: isSelected
                        ? kColorPrimary
                        : (isLight ? Colors.black54 : kColorAccent.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    m.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? kColorPrimary
                          : (isLight ? Colors.black54 : kColorAccent.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }

  static const _excludedTopics = {'Vocabulary Drill', 'Grammar Practice'};

  Widget _buildTopicSelector(AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    if (state.appMode != AppMode.practice) return const SizedBox.shrink();
    final topics = kTopics.where((t) => !_excludedTopics.contains(t)).toList();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          final isActive = state.selectedTopic == topic;
          return GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await state.selectTopic(topic);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? kColorPrimary.withValues(alpha: 0.12)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? kColorPrimary.withValues(alpha: 0.4)
                      : cs.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    kTopicIcons[topic] ?? Icons.chat_rounded,
                    size: 14,
                    color: isActive ? kColorPrimary : cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tTopic(topic, state.nativeLanguage),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? kColorPrimary : cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
