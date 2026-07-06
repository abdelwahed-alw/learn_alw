import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state, greeting, emoji),
                const SizedBox(height: 24),
                _buildGlobalProgress(context, state),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'continueLearning'.tr()),
                const SizedBox(height: 14),
                _buildRecentCard(state),
                const SizedBox(height: 28),
                _DailyQuoteWidget(),
                const SizedBox(height: 28),
                _buildSectionTitle(context, 'quickStats'.tr()),
                const SizedBox(height: 14),
                _buildQuickStats(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppStateModel state, String greeting, String emoji) {
    final cs = Theme.of(context).colorScheme;
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
                        color: cs.onSurface.withValues(alpha: 0.5),
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
                style: TextStyle(
                  color: cs.onSurface,
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

  Widget _buildGlobalProgress(BuildContext context, AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    final pct = (state.overallProgressPercent * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
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
                  color: cs.onSurface.withValues(alpha: 0.7),
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
              backgroundColor: cs.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip(context, Icons.check_circle_rounded,
                  '${state.totalExercisesDone}', 'exercises'.tr()),
              const SizedBox(width: 16),
              _statChip(context, Icons.local_fire_department_rounded,
                  '${state.streakDays}', 'dayStreak'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildQuickStats(AppStateModel state) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.menu_book_rounded,
            value: '${state.beginnerVocabulary.length}',
            label: 'words'.tr(),
            color: kColorPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.assignment_rounded,
            value: '${state.totalExercisesDone}',
            label: 'exercises'.tr(),
            color: const Color(0xFFFF8E53),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${state.streakDays}',
            label: 'streak'.tr(),
            color: kColorPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Stat Card ───────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
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

// ─── Daily Quote Widget ─────────────────────────────────────────────────────────

class _DailyQuoteWidget extends StatefulWidget {
  const _DailyQuoteWidget();

  @override
  State<_DailyQuoteWidget> createState() => _DailyQuoteWidgetState();
}

class _DailyQuoteWidgetState extends State<_DailyQuoteWidget> {
  final GeminiApiService _api = GeminiApiService();
  DailyQuote? _quote;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final String uniqueSeed = DateTime.now().millisecondsSinceEpoch.toString();
    final List<String> themes = ['patience', 'courage', 'time', 'friendship', 'hope', 'wisdom', 'kindness', 'dreams', 'overcoming failure', 'success', 'nature', 'hard work', 'forgiveness', 'gratitude', 'moving forward'];
    final String randomTheme = themes[DateTime.now().millisecondsSinceEpoch % themes.length];
    try {
      final quote = await _api.generateDailyQuote(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        uniqueSeed: uniqueSeed,
        theme: randomTheme,
      );
      if (mounted) setState(() { _quote = quote; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 18, width: double.infinity, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)))),
              const SizedBox(height: 10),
              Container(height: 18, width: MediaQuery.of(context).size.width * 0.6, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)))),
              const SizedBox(height: 10),
              Container(height: 18, width: MediaQuery.of(context).size.width * 0.4, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)))),
              const SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(height: 14, width: MediaQuery.of(context).size.width * 0.3, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)))),
              ),
            ],
          ),
        ),
      );
    }
    if (_quote == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => kPrimaryGradient.createShader(bounds),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '"${_quote!.quote}"',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _quote!.translation,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.normal,
                height: 1.4,
              ),
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
