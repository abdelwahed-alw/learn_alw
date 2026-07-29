import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'writing_screen.dart';
import 'grammar_screen.dart';
import 'vocabulary_screen.dart';
import 'reading_screen.dart';
import 'listening_screen.dart';
import 'speaking_screen.dart';

class CategoriesTab extends StatelessWidget {
  final VoidCallback? onNavigateProfile;
  const CategoriesTab({super.key, this.onNavigateProfile});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final categories = [
          (
            'writing'.tr(),
            Icons.edit_rounded,
            const Color(0xFFFF6B6B),
            state.writingProgress,
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WritingScreen(),
                  ),
                ),
          ),
          (
            'grammar'.tr(),
            Icons.text_fields_rounded,
            const Color(0xFFFF8E53),
            state.grammarProgress,
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrammarScreen(),
                  ),
                ),
          ),
          (
            'vocabulary'.tr(),
            Icons.spellcheck_rounded,
            const Color(0xFF2ECC71),
            state.vocabularyProgress,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen())),
          ),
          (
            'reading'.tr(),
            Icons.auto_stories_rounded,
            const Color(0xFF3498DB),
            state.readingProgress,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReadingScreen())),
          ),
          (
            'speaking'.tr(),
            Icons.record_voice_over_rounded,
            const Color(0xFF9B59B6),
            state.speakingProgress,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SpeakingScreen())),
          ),
          (
            'listening'.tr(),
            Icons.headphones_rounded,
            const Color(0xFF1ABC9C),
            state.listeningProgress,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ListeningScreen())),
          ),
        ];

        final behind = categories.where((c) => c.$4 < 0.8).toList();
        final weakest = behind.isEmpty ? null : behind.reduce((a, b) => a.$4 < b.$4 ? a : b);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!state.hasApiKey)
                _buildApiKeyWarning(context)
              else if (weakest != null)
                _buildRecommendCard(context, weakest),
              const SizedBox(height: 16),
              Text(
                'skillCategories'.tr(),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _CategoryCard(
                      icon: cat.$2,
                      label: cat.$1,
                      color: cat.$3,
                      progress: cat.$4,
                      onTap: cat.$5,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApiKeyWarning(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorPrimary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: kColorPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'configureApiKeyFirst'.tr(),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'apiKeyRequired'.tr(),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNavigateProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'apiKeySetup'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendCard(
    BuildContext context,
    (String, IconData, Color, double, VoidCallback) weakest,
  ) {
    final pct = (weakest.$4 * 100).round();
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        weakest.$5();
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(weakest.$2, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'weakAreaTitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                    Text(
                      '${weakest.$1} — $pct%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double progress;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: cs.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 0.8 ? const Color(0xFF2ECC71) : color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
