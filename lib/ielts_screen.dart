import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'ui_strings.dart';

class IeltsScreen extends StatefulWidget {
  const IeltsScreen({super.key});

  @override
  State<IeltsScreen> createState() => _IeltsScreenState();
}

class _IeltsScreenState extends State<IeltsScreen> {
  final TextEditingController _answerController = TextEditingController();
  int? _selectedOptionIndex;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final textDirection =
            textDirectionForCode(state.nativeLanguage);
        return Directionality(
          textDirection: textDirection,
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorPrimary.withValues(alpha: 0.1),
                    backgroundBlendMode: BlendMode.screen,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24.0, 100.0, 24.0, 24.0),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _buildModeHeader(state),
                          const SizedBox(height: 20),
                          _buildExerciseTabs(state),
                          const SizedBox(height: 24),
                          _buildExerciseContent(state),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeHeader(AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: cs.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IELTS Exam Prep',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${t('topicLabel', state.nativeLanguage)}: ${tTopic(state.selectedTopic, state.nativeLanguage)}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTabs(AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    final types = IeltsExerciseType.values;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Row(
        children: types.map((type) {
          final isSelected =
              state.ieltsExerciseType == type;
          final label = _ieltsTypeLabel(type);
          final icon = _ieltsTypeIcon(type);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                state.setIeltsExerciseType(type);
                _selectedOptionIndex = null;
                _answerController.clear();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kColorPrimary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? kColorPrimary
                          : kColorAccent.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? kColorPrimary
                            : kColorAccent.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _ieltsTypeLabel(IeltsExerciseType type) {
    switch (type) {
      case IeltsExerciseType.fillBlanks:
        return 'Fill Blanks';
      case IeltsExerciseType.sentenceCompletion:
        return 'Complete';
      case IeltsExerciseType.writingPractice:
        return 'Writing';
    }
  }

  IconData _ieltsTypeIcon(IeltsExerciseType type) {
    switch (type) {
      case IeltsExerciseType.fillBlanks:
        return Icons.space_bar_rounded;
      case IeltsExerciseType.sentenceCompletion:
        return Icons.edit_note_rounded;
      case IeltsExerciseType.writingPractice:
        return Icons.feed_rounded;
    }
  }

  Widget _buildExerciseContent(AppStateModel state) {
    if (state.ieltsLoading) {
      return _buildShimmerLoading();
    }

    // If no exercise yet, show generate buttons
    if (!state.ieltsHasExercise) {
      return _buildGenerateSection(state);
    }

    switch (state.ieltsExerciseType) {
      case IeltsExerciseType.fillBlanks:
        return _buildFillBlanksContent(state);
      case IeltsExerciseType.sentenceCompletion:
        return _buildSentenceCompletionContent(state);
      case IeltsExerciseType.writingPractice:
        return _buildWritingContent(state);
    }
  }

  Widget _buildShimmerLoading() {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.outline.withValues(alpha: 0.2),
      highlightColor: cs.outline.withValues(alpha: 0.5),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateSection(AppStateModel state) {
    final type = state.ieltsExerciseType;
    String title;
    String desc;
    IconData icon;
    switch (type) {
      case IeltsExerciseType.fillBlanks:
        title = 'Fill in the Blanks';
        desc =
            'Read the passage and select the correct word to fill the gap. Tests reading comprehension and vocabulary.';
        icon = Icons.space_bar_rounded;
      case IeltsExerciseType.sentenceCompletion:
        title = 'Sentence Completion';
        desc =
            'Complete the sentence stem with your own words. The AI will evaluate grammar and context.';
        icon = Icons.edit_note_rounded;
      case IeltsExerciseType.writingPractice:
        title = 'Writing Practice';
        desc =
            'Write a full response to an IELTS-style prompt. Get a band score estimate and improvement suggestions.';
        icon = Icons.feed_rounded;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    Icon(icon, color: kColorPrimary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildGenerateButton(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(AppStateModel state) {
    final generateMap = {
      IeltsExerciseType.fillBlanks:
          () => state.generateIeltsFillBlank(),
      IeltsExerciseType.sentenceCompletion:
          () => state.generateIeltsSentenceStart(),
      IeltsExerciseType.writingPractice:
          () => state.generateIeltsWritingPrompt(),
    };
    final onGenerate = generateMap[state.ieltsExerciseType]!;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final error = await onGenerate();
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: kColorError,
            ),
          );
        }
      },
      child: Container(
        height: 52,
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
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Generate Exercise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fill-in-the-blanks Content ──────────────────────────────────────────────

  Widget _buildFillBlanksContent(AppStateModel state) {
    final passageParts =
        state.ieltsPassage.split('______');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Passage display
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kColorPrimary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: kColorPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reading Passage',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.7),
                  children: [
                    if (passageParts.isNotEmpty)
                      TextSpan(
                          text: passageParts[0]),
                    WidgetSpan(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '______',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    if (passageParts.length > 1)
                      TextSpan(
                          text: passageParts[1]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Options
        Text(
          'Select the correct word:',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...state.ieltsOptions
            .asMap()
            .entries
            .map((entry) {
          final cs = Theme.of(context).colorScheme;
          final idx = entry.key;
          final option = entry.value;
          final isSelected =
              _selectedOptionIndex == idx;
          final hasFeedback =
              state.ieltsFeedback.isNotEmpty;
          final isCorrect = option ==
              state.ieltsCorrectAnswer;
          Color? borderColor;
          if (hasFeedback) {
            borderColor = isCorrect
                ? const Color(0xFF2ECC71)
                : (isSelected
                    ? kColorError
                    : cs.outline.withValues(alpha: 0.5));
          }
          return Padding(
            padding:
                const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: hasFeedback
                  ? null
                  : () {
                      HapticFeedback
                          .lightImpact();
                      setState(() =>
                          _selectedOptionIndex =
                              idx);
                    },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasFeedback && isCorrect
                      ? const Color(0xFF2ECC71)
                          .withValues(alpha: 0.1)
                      : isSelected
                          ? kColorPrimary
                              .withValues(
                                  alpha: 0.1)
                          : Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor ??
                        (isSelected
                            ? kColorPrimary
                                .withValues(
                                    alpha: 0.4)
                            : cs.outline.withValues(alpha: 0.5)),
                    width:
                        isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: hasFeedback &&
                                isCorrect
                            ? const Color(
                                    0xFF2ECC71)
                            : isSelected
                                ? kColorPrimary
                                : cs.outline.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(
                                8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(
                              65 + idx),
                          style: TextStyle(
                            color: isSelected ||
                                    (hasFeedback &&
                                        isCorrect)
                                ? Colors.white
                                : cs.onSurface.withValues(alpha: 0.6),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: hasFeedback &&
                                  isCorrect
                              ? const Color(
                                  0xFF2ECC71)
                              : cs.onSurface,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasFeedback && isCorrect)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2ECC71),
                        size: 22,
                      ),
                    if (hasFeedback &&
                        isSelected &&
                        !isCorrect)
                      const Icon(
                        Icons.cancel_rounded,
                        color: kColorError,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        // Submit / Feedback
        if (state.ieltsFeedback.isEmpty)
          _buildSmallSubmitButton(
            label: 'Check Answer',
            onTap: () {
              if (_selectedOptionIndex == null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please select an option first.'),
                  ),
                );
                return;
              }
              final answer = state.ieltsOptions[
                  _selectedOptionIndex!];
              state.submitIeltsFillBlank(answer);
            },
          )
        else ...[
          _buildFeedbackCard(state),
          const SizedBox(height: 16),
          _buildTryAgainButton(state),
        ],
      ],
    );
  }

  // ─── Sentence Completion Content ─────────────────────────────────────────────

  Widget _buildSentenceCompletionContent(
      AppStateModel state) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kColorPrimary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: kColorPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Complete the sentence',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                  children: [
                    TextSpan(
                      text:
                          '${state.ieltsPromptOrStart} ',
                    ),
                    WidgetSpan(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B)
                              .withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '…',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (state.ieltsFeedback.isEmpty) ...[
          TextField(
            controller: _answerController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Complete the sentence…',
            ),
          ),
          const SizedBox(height: 16),
          _buildSmallSubmitButton(
            label: 'Submit Completion',
            onTap: () {
              final text =
                  _answerController.text.trim();
              if (text.isEmpty) return;
              FocusScope.of(context).unfocus();
              state.submitIeltsSentenceCompletion(
                  text);
            },
          ),
        ] else ...[
          _buildSentenceEvalFeedback(state),
          const SizedBox(height: 16),
          _buildTryAgainButton(state),
        ],
      ],
    );
  }

  // ─── Writing Practice Content ────────────────────────────────────────────────

  Widget _buildWritingContent(AppStateModel state) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kColorPrimary
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.feed_rounded,
                      color: kColorPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Writing Task',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                state.ieltsPromptOrStart,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ),
        if (state.ieltsFeedback.isEmpty) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _answerController,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText:
                  'Write your essay here…',
            ),
          ),
          const SizedBox(height: 16),
          _buildSmallSubmitButton(
            label: 'Submit for Evaluation',
            onTap: () {
              final text =
                  _answerController.text.trim();
              if (text.isEmpty) return;
              if (text.length < 50) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please write at least 50 characters for a meaningful evaluation.'),
                  ),
                );
                return;
              }
              FocusScope.of(context).unfocus();
              state.submitIeltsWriting(text);
            },
          ),
        ] else ...[
          const SizedBox(height: 24),
          _buildWritingFeedback(state),
          const SizedBox(height: 16),
          _buildTryAgainButton(state),
        ],
      ],
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────────────────────────

  Widget _buildSmallSubmitButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  kColorPrimary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                label.contains('Generate')
                    ? Icons.auto_awesome_rounded
                    : label.contains('Check')
                        ? Icons.check_circle_outline_rounded
                        : Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.5),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.ieltsFeedback
                        .startsWith('✓')
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: state.ieltsFeedback
                        .startsWith('✓')
                    ? const Color(0xFF2ECC71)
                    : kColorAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Result',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.ieltsFeedback,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          if (state.ieltsExplanation
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                state.ieltsExplanation,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentenceEvalFeedback(
      AppStateModel state) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.5),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.ieltsSentenceCorrect
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: state.ieltsSentenceCorrect
                    ? const Color(0xFF2ECC71)
                    : kColorAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                state.ieltsSentenceCorrect
                    ? '✓ Good Completion'
                    : 'Feedback',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: state
                              .ieltsSentenceCorrect
                          ? const Color(0xFF2ECC71)
                          : cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.ieltsFeedback,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          if (state.ieltsSuggestedCompletion
              .isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                    color: cs.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model Completion:',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state
                        .ieltsSuggestedCompletion,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWritingFeedback(
      AppStateModel state) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        // Band Score
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: kPrimaryGradient,
            boxShadow: [
              BoxShadow(
                color: kColorPrimary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Estimated Band Score',
                style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.ieltsBandScore > 0
                    ? state.ieltsBandScore
                        .toStringAsFixed(1)
                    : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Feedback
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.feedback_rounded,
                    color: kColorAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Feedback',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                state.ieltsFeedback,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Corrections
        if (state.ieltsCorrections.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kColorError
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: kColorError,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Corrections',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state.ieltsCorrections
                    .map((correction) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                            bottom: 8),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          margin:
                              const EdgeInsets.only(
                                  top: 4),
                          width: 6,
                          height: 6,
                          decoration:
                              BoxDecoration(
                            color: kColorError,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                            width: 10),
                        Expanded(
                          child: Text(
                            correction,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Vocabulary Suggestions
        if (state.ieltsVocabSuggestions
            .isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2ECC71)
                    .withValues(alpha: 0.3),
              ),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF2ECC71)
                                .withValues(
                                    alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons
                            .spellcheck_rounded,
                        color: Color(0xFF2ECC71),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Vocabulary Upgrades',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state
                    .ieltsVocabSuggestions
                    .entries
                    .map((entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                            bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          padding:
                              const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline
                                .withValues(
                                    alpha: 0.3),
                            borderRadius:
                                BorderRadius
                                    .circular(8),
                          ),
                          child: Text(
                            entry.key,
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                              decoration:
                                  TextDecoration
                                      .lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 12),
                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 16,
                          color: const Color(
                              0xFF2ECC71),
                        ),
                        const SizedBox(
                            width: 12),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFF2ECC71),
                            fontWeight:
                                FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTryAgainButton(AppStateModel state) {
    final generateMap = {
      IeltsExerciseType.fillBlanks:
          () => state.generateIeltsFillBlank(),
      IeltsExerciseType.sentenceCompletion:
          () => state.generateIeltsSentenceStart(),
      IeltsExerciseType.writingPractice:
          () => state.generateIeltsWritingPrompt(),
    };
    final onGenerate =
        generateMap[state.ieltsExerciseType]!;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        _selectedOptionIndex = null;
        _answerController.clear();
        final error = await onGenerate();
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: kColorError,
            ),
          );
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                kColorPrimary.withValues(alpha: 0.4),
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: kColorPrimary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Try Another',
                style: TextStyle(
                  color: kColorPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
