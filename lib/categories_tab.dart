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
import 'ui_strings.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final categories = [
          (
            'Writing',
            Icons.edit_rounded,
            const Color(0xFFFF6B6B),
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WritingScreen(),
                  ),
                ),
          ),
          (
            'Grammar',
            Icons.text_fields_rounded,
            const Color(0xFFFF8E53),
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrammarScreen(),
                  ),
                ),
          ),
          (
            'Vocabulary',
            Icons.spellcheck_rounded,
            const Color(0xFF2ECC71),
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen())),
          ),
          (
            'Reading',
            Icons.auto_stories_rounded,
            const Color(0xFF3498DB),
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReadingScreen())),
          ),
          (
            'Speaking',
            Icons.record_voice_over_rounded,
            const Color(0xFF9B59B6),
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SpeakingScreen())),
          ),
          (
            'Listening',
            Icons.headphones_rounded,
            const Color(0xFF1ABC9C),
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ListeningScreen())),
          ),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'skillCategories'),
                style: TextStyle(
                  color: kColorText.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
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
                      onTap: cat.$4,
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
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: kColorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
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
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: kColorText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr(context, 'practice'),
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
