import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onNavigateExercises;

  const HomeTab({super.key, this.onNavigateExercises});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final hour = DateTime.now().hour;
        String greeting;
        String emoji;
        if (hour < 12) {
          greeting = 'goodMorning'.tr();
          emoji = '☀️';
        } else if (hour < 17) {
          greeting = 'goodAfternoon'.tr();
          emoji = '🌤️';
        } else if (hour < 21) {
          greeting = 'goodEvening'.tr();
          emoji = '🌙';
        } else {
          greeting = 'lateSession'.tr();
          emoji = '🌜';
        }

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state, greeting, emoji),
                      const SizedBox(height: 24),
                      _buildGlobalProgress(state),
                      const SizedBox(height: 24),
                      _buildSectionTitle('continueLearning'.tr()),
                      const SizedBox(height: 14),
                      _buildRecentCard(state),
                      const SizedBox(height: 24),
                      _buildSectionTitle('exerciseCategories'.tr()),
                      const SizedBox(height: 14),
                      _buildCategoryGrid(state),
                      const SizedBox(height: 24),
                      _buildSectionTitle('quickStats'.tr()),
                      const SizedBox(height: 14),
                      _buildStatsRow(state),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppStateModel state, String greeting, String emoji) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'salearn'.tr(),
                      style: TextStyle(
                        color: kColorText.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: const TextStyle(
                  color: kColorText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _LevelBadge(level: state.proficiencyLevel),
      ],
    );
  }

  Widget _buildGlobalProgress(AppStateModel state) {
    final pct = (state.overallProgressPercent * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: kColorPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'overallProgress'.tr(),
                style: TextStyle(
                  color: kColorText.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: TextStyle(
                  color: kColorPrimary.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.overallProgressPercent,
              backgroundColor: kColorBorder,
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip(Icons.check_circle_rounded,
                  '${state.totalExercisesDone}', 'exercises'.tr()),
              const SizedBox(width: 16),
              _statChip(Icons.local_fire_department_rounded,
                  '${state.streakDays}', 'dayStreak'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kColorTextMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: kColorText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: kColorTextMuted.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: kColorText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildRecentCard(AppStateModel state) {
    final modeLabel = _labelForMode(state.lastAccessedMode);
    if (!state.hasApiKey ||
        !state.ieltsHasExercise &&
            !state.hasQuestion &&
            !state.beginnerHasSentence) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          state.setAppMode(state.lastAccessedMode);
          onNavigateExercises?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'startLearning'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        state.setAppMode(state.lastAccessedMode);
        onNavigateExercises?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'continueLearning'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForMode(AppMode mode) {
    switch (mode) {
      case AppMode.ielts:
        return 'ieltsExamPrep'.tr();
      case AppMode.beginner:
        return 'vocabularyPractice'.tr();
      case AppMode.categories:
        return 'skillExercises'.tr();
      case AppMode.practice:
        return 'practiceSession'.tr();
    }
  }

  Widget _buildCategoryGrid(AppStateModel state) {
    final categories = [
      ('writing'.tr(), Icons.edit_rounded, kTopics[0], 0.3),
      ('grammar'.tr(), Icons.text_fields_rounded, kTopics[4], 0.5),
      ('vocabulary'.tr(), Icons.spellcheck_rounded, kTopics[3], 0.4),
      ('reading'.tr(), Icons.auto_stories_rounded, kTopics[1], 0.2),
      ('speaking'.tr(), Icons.record_voice_over_rounded, kTopics[5], 0.1),
      ('listening'.tr(), Icons.headphones_rounded, kTopics[2], 0.0),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final progress = (state.topicProgress[cat.$3] ?? 0) / 10.0;
        return _CategoryCard(
          icon: cat.$2,
          label: cat.$1,
          progress: progress.clamp(0.0, 1.0),
        );
      },
    );
  }

  Widget _buildStatsRow(AppStateModel state) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '${state.beginnerVocabulary.length}',
            label: 'words'.tr(),
            color: kColorPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment_rounded,
            value: '${state.totalExercisesDone}',
            label: 'exercises'.tr(),
            color: const Color(0xFFFF8E53),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${state.streakDays}',
            label: 'streak'.tr(),
            color: const Color(0xFF2ECC71),
          ),
        ),
      ],
    );
  }
}

// ─── Category Card ──────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double progress;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kColorPrimary, size: 18),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: kColorText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: kColorBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.8 ? const Color(0xFF2ECC71) : kColorPrimary,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level Badge ────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelEmoji(level),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            level,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            levelLabel(level),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
