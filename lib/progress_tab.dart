import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';

class ProgressTab extends StatelessWidget {
  final VoidCallback? onNavigateExercises;
  const ProgressTab({super.key, this.onNavigateExercises});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, state),
                      const SizedBox(height: 24),
                      _buildOverviewCards(state),
                      const SizedBox(height: 24),
                      _buildTopicBreakdown(context, state),
                      const SizedBox(height: 24),
                      _buildSkillBreakdown(context, state),
                      const SizedBox(height: 24),
                      _buildVocabularySection(context, state),
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

  Widget _buildHeader(BuildContext context, AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'progressTab'.tr(),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'trackYourLearning'.tr(),
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(AppStateModel state) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            icon: Icons.assignment_rounded,
            label: 'totalExercises'.tr(),
            value: '${state.totalExercisesDone}',
            color: kColorPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            icon: Icons.menu_book_rounded,
            label: 'wordsLearned'.tr(),
            value: '${state.beginnerVocabulary.length}',
            color: const Color(0xFFFF8E53),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            icon: Icons.local_fire_department_rounded,
            label: 'dayStreak'.tr(),
            value: '${state.streakDays}',
            color: kColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicBreakdown(BuildContext context, AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    final topics = state.topicProgress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: cs.onSurface.withValues(alpha: 0.4), size: 40),
            const SizedBox(height: 8),
            Text(
              'noExercisesYet'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onNavigateExercises,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'startAnExercise'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'topicBreakdown'.tr(),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: cs.outline.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: topics.take(8).map((entry) {
              final maxVal = topics.first.value;
              final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key.length > 14
                            ? '${entry.key.substring(0, 14)}…'
                            : entry.key,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: cs.outline.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kColorPrimary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillBreakdown(BuildContext context, AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    final skills = <(String, IconData, double)>[
      ('writing'.tr(), Icons.edit_rounded, state.writingProgress),
      ('grammar'.tr(), Icons.text_fields_rounded, state.grammarProgress),
      ('vocabulary'.tr(), Icons.spellcheck_rounded, state.vocabularyProgress),
      ('reading'.tr(), Icons.auto_stories_rounded, state.readingProgress),
      ('speaking'.tr(), Icons.record_voice_over_rounded, state.speakingProgress),
      ('listening'.tr(), Icons.headphones_rounded, state.listeningProgress),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'skillsBreakdown'.tr(),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: skills.length,
          itemBuilder: (_, index) {
            final s = skills[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
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
                        child: Icon(s.$2, color: kColorPrimary, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        '${(s.$3 * 100).round()}%',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.$1,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.$3,
                      backgroundColor: cs.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        s.$3 >= 0.8 ? const Color(0xFF2ECC71) : kColorPrimary,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVocabularySection(BuildContext context, AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    final vocab = state.beginnerVocabulary;
    if (vocab.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'vocabulary'.tr()} (${vocab.length})',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: cs.outline.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: vocab.length.clamp(0, 20),
            separatorBuilder: (_, __) => Divider(
                color: cs.outline.withValues(alpha: 0.3)),
            itemBuilder: (context, index) {
              final entry = vocab[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2ECC71),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry['word'] ?? '',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry['meaning'] ?? '',
                        style: TextStyle(
                          color:
                              cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (vocab.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child:              Text(
                '+ ${vocab.length - 20} ${'moreWords'.tr()}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Overview Card ──────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
