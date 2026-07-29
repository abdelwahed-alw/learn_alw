import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'grammar_screen.dart';
import 'listening_screen.dart';
import 'reading_screen.dart';
import 'speaking_screen.dart';
import 'vocabulary_screen.dart';
import 'writing_screen.dart';

class ProgressTab extends StatefulWidget {
  final VoidCallback? onNavigateExercises;
  const ProgressTab({super.key, this.onNavigateExercises});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                      _buildWeeklySection(context, state),
                      if (state.totalExercisesDone > 0) ...[
                        const SizedBox(height: 24),
                        _buildOverviewCards(state),
                        const SizedBox(height: 24),
                        _buildTopicBreakdown(context, state),
                        const SizedBox(height: 24),
                        _buildSkillBreakdown(context, state),
                        const SizedBox(height: 24),
                        _buildVocabularySection(context, state),
                      ],
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
          'trackYourLearningJourney'.tr(),
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySection(BuildContext context, AppStateModel state) {
    final hasActivity = state.totalExercisesDone > 0;
    if (!hasActivity) {
      return _EmptyCard(onStart: widget.onNavigateExercises);
    }

    final cs = Theme.of(context).colorScheme;
    final counts = state.weeklyActivityCounts;
    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 9999);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.today_rounded,
                label: 'today'.tr(),
                value: '${state.todayExercisesCount} / $kDailyExerciseGoal',
                subtitle: 'dailyGoal'.tr(),
                color: kColorPrimary,
                progress: (state.todayExercisesCount / kDailyExerciseGoal)
                    .clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.date_range_rounded,
                label: 'thisWeek'.tr(),
                value: '${state.weeklyExercisesCount}',
                subtitle: 'exercisesDone'.tr(),
                color: const Color(0xFF2ECC71),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecor(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'last7Days'.tr(),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: Row(
                  children: List.generate(7, (i) {
                    final d = DateTime.now()
                        .subtract(Duration(days: 6 - i));
                    final count = counts[i];
                    final ratio = count / maxCount;
                    final dayLabel = DateFormat.E(context.locale.toString())
                        .format(d);
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          if (count > 0) const SizedBox(height: 4),
                          Expanded(
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: ratio.toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? kColorPrimary
                                      : cs.outline.withValues(alpha: 0.2),
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color:
                                  cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildWeakAreaCard(context, state),
      ],
    );
  }

  Widget _buildWeakAreaCard(BuildContext context, AppStateModel state) {
    final skills = [
      ('writing', state.writingProgress, const WritingScreen()),
      ('grammar', state.grammarProgress, const GrammarScreen()),
      ('vocabulary', state.vocabularyProgress, const VocabularyScreen()),
      ('reading', state.readingProgress, const ReadingScreen()),
      ('speaking', state.speakingProgress, const SpeakingScreen()),
      ('listening', state.listeningProgress, const ListeningScreen()),
    ].where((s) => s.$2 < 0.8).toList();

    if (skills.isEmpty) return const SizedBox.shrink();

    final weakest = skills.reduce((a, b) => a.$2 < b.$2 ? a : b);
    final pct = (weakest.$2 * 100).round();

    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => weakest.$3));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecor(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kColorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: kColorPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'weakAreaTitle'.tr(),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                    Text(
                      '${weakest.$1} — $pct%',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'practiceNow'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final topics = state.topicProgress.entries.toList();
    topics.sort((a, b) => (a.value / 10.0).compareTo(b.value / 10.0));
    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecor(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: cs.onSurface.withValues(alpha: 0.4), size: 40),
            const SizedBox(height: 8),
            Text(
              'noExercisesCompletedYet'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onNavigateExercises,
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

    final goal = kDailyExerciseGoal;
    final displayTopics = topics.take(8).toList();
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
          decoration: _cardDecor(context),
          child: Column(
            children: displayTopics.map((entry) {
              final ratio =
                  (entry.value / goal).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    state.setSelectedTopic(entry.key);
                    state.setAppMode(AppMode.practice);
                    widget.onNavigateExercises?.call();
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          topicLocaleKey(entry.key).tr(),
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
                            backgroundColor:
                                cs.outline.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ratio >= 1.0
                                  ? const Color(0xFF2ECC71)
                                  : kColorPrimary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
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
                      Icon(Icons.chevron_right_rounded,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
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
    final skills = <(String, IconData, double, Widget)>[
      ('writingKey'.tr(), Icons.edit_rounded, state.writingProgress,
          const WritingScreen()),
      ('grammarKey'.tr(), Icons.text_fields_rounded, state.grammarProgress,
          const GrammarScreen()),
      ('vocabularyKey'.tr(), Icons.spellcheck_rounded,
          state.vocabularyProgress, const VocabularyScreen()),
      ('readingKey'.tr(), Icons.auto_stories_rounded, state.readingProgress,
          const ReadingScreen()),
      ('speakingKey'.tr(), Icons.record_voice_over_rounded,
          state.speakingProgress, const SpeakingScreen()),
      ('listeningKey'.tr(), Icons.headphones_rounded, state.listeningProgress,
          const ListeningScreen()),
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
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: skills.length,
          itemBuilder: (_, index) {
            final s = skills[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => s.$4));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecor(context),
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
                          child:
                              Icon(s.$2, color: kColorPrimary, size: 18),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                        backgroundColor:
                            cs.outline.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          s.$3 >= 0.8
                              ? const Color(0xFF2ECC71)
                              : kColorPrimary,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
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

    if (vocab.isEmpty) {
      return _EmptyCard(
        title: 'vocabulary'.tr(),
        subtitle: 'noVocabularyYet'.tr(),
        onStart: null,
      );
    }

    final matches = vocab.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery;
      return (e['word'] ?? '').toLowerCase().contains(q) ||
          (e['meaning'] ?? '').toLowerCase().contains(q);
    }).toList();

    final maxItems = 50;
    final showMore = matches.length > maxItems;

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
        if (vocab.length > 5) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'searchVocabulary'.tr(),
              hintStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: cs.outline.withValues(alpha: 0.5)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
            boxShadow: _cardShadow(context),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: matches.length.clamp(0, maxItems),
            separatorBuilder: (_, __) =>
                Divider(color: cs.outline.withValues(alpha: 0.3)),
            itemBuilder: (context, index) {
              final entry = matches[index];
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
                          color: cs.onSurface.withValues(alpha: 0.6),
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
        if (showMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '+ ${matches.length - maxItems} ${'moreWords'.tr()}',
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

  BoxDecoration _cardDecor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      boxShadow: _cardShadow(context),
    );
  }

  List<BoxShadow> _cardShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2))]
        : [];
  }
}

class _EmptyCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onStart;

  const _EmptyCard({this.title, this.subtitle, this.onStart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTitle = title != null;
    final showSubtitle = subtitle != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              color: cs.onSurface.withValues(alpha: 0.4), size: 40),
          if (showTitle) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (showSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
          if (onStart != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onStart,
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
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final double? progress;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.progress,
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
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: cs.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))]
            : [],
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
