// lib/main_screen_body.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'app_state_model.dart';
import 'constants.dart';

class MainScreenBody extends StatefulWidget {
  const MainScreenBody({super.key});

  @override
  State<MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  final TextEditingController _answerController = TextEditingController();

  Future<void> _submitAnswer(AppStateModel state) async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      await state.submitAnswer(text);
      _answerController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kColorError),
        );
      }
    }
  }

  void _showTranslationSheet(BuildContext context, String text) {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your API key first.'),
          backgroundColor: kColorError,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TranslationSheet(
        text: text,
        model: state,
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, child) {
        final textDirection = textDirectionForCode(state.nativeLanguage);
        return Directionality(
          textDirection: textDirection,
          child: Stack(
            children: [
              Positioned(
                top: -100, right: -100,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorPrimary.withValues(alpha: 0.15),
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
                      padding: const EdgeInsets.fromLTRB(24.0, 100.0, 24.0, 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.currentQuestion.isNotEmpty ||
                              state.loadingPhase == LoadingPhase.generatingQ)
                            _buildHeaderBanner(state),
                          if (state.currentQuestion.isNotEmpty ||
                              state.loadingPhase == LoadingPhase.generatingQ)
                            const SizedBox(height: 24),
                          _buildQuestionCard(state),
                          if (state.currentQuestion.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildInputArea(state),
                            const SizedBox(height: 24),
                            _buildFeedbackSection(state),
                            const SizedBox(height: 24),
                            _buildExamplesSection(state),
                          ],
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

  Widget _buildHeaderBanner(AppStateModel state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kColorSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Topic: ${state.selectedTopic}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kColorPrimary,
                          ),
                    ),
                  ),
                  // Level badge in banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kColorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kColorPrimary.withValues(alpha: 0.3),
                      ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LanguageBadge(
                      label: languageLabelFromCode(state.nativeLanguage)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: kColorTextMuted, size: 16),
                  ),
                  _LanguageBadge(
                    label: languageLabelFromCode(state.targetLanguage),
                    isTarget: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(AppStateModel state) {
    if (state.loadingPhase == LoadingPhase.generatingQ) {
      return _buildShimmerBox(height: 120);
    }
    if (state.currentQuestion.isEmpty) {
      return _buildWelcomeDashboard(state);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: kCardGradient,
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: kColorBorder),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded,
                    color: kColorPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Translate or Answer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: kColorTextMuted,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              // Translate button
              _TranslateButton(
                onTap: () =>
                    _showTranslationSheet(context, state.currentQuestion),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            state.currentQuestion,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppStateModel state) {
    final isSubmitting = state.loadingPhase == LoadingPhase.submitting;
    final isDisabled = state.currentQuestion.isEmpty || isSubmitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answerController,
          enabled: !isDisabled,
          maxLines: 4,
          minLines: 3,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText:
                'Type your answer in ${languageLabelFromCode(state.targetLanguage)}...',
          ),
        ),
        const SizedBox(height: 16),
        _AnimatedSubmitButton(
          isDisabled: isDisabled,
          isSubmitting: isSubmitting,
          onTap: () => _submitAnswer(state),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(AppStateModel state) {
    if (state.loadingPhase == LoadingPhase.submitting) {
      return _buildShimmerBox(height: 150);
    }
    if (state.feedback.isEmpty) return const SizedBox.shrink();
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: kPremiumCurve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: kPremiumCurve,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: kColorAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kColorAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: kColorAccent.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: kColorAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Feedback',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: kColorAccent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Translate feedback
                    _TranslateButton(
                      onTap: () =>
                          _showTranslationSheet(context, state.feedback),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: state.feedback.isNotEmpty ? 1.0 : 0.0,
                  child: Text(
                    state.feedback,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamplesSection(AppStateModel state) {
    if (state.loadingPhase == LoadingPhase.submitting) {
      return Column(
        children: [
          _buildShimmerBox(height: 80),
          const SizedBox(height: 12),
          _buildShimmerBox(height: 80),
          const SizedBox(height: 12),
          _buildShimmerBox(height: 80),
        ],
      );
    }
    if (state.examples.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Better ways to say it:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: kColorTextMuted,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...state.examples.asMap().entries.map((entry) {
          final index = entry.key;
          final example = entry.value;
          if (example.isEmpty) return const SizedBox.shrink();
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: kPremiumCurve,
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - opacity)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExampleCard(
                index: index,
                text: example,
                onTranslate: () => _showTranslationSheet(context, example),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        if (state.nextQuestionPreview.isNotEmpty)
          _buildNextQuestionButton(state)
        else if (state.feedback.isNotEmpty)
          _buildShimmerBox(height: 90),
      ],
    );
  }

  Widget _buildNextQuestionButton(AppStateModel state) {
    return _NextQuestionButton(
      previewText: state.nextQuestionPreview,
      onTap: () async {
        final error = await state.generateNextQuestion();
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: kColorError),
          );
        }
      },
    );
  }

  Widget _buildShimmerBox({required double height}) {
    return Shimmer.fromColors(
      baseColor: kColorSurface,
      highlightColor: kColorBorder,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: kColorSurface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildWelcomeDashboard(AppStateModel state) {
    // Time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else if (hour < 21) {
      greeting = 'Good Evening';
      emoji = '🌙';
    } else {
      greeting = 'Ready for a late session?';
      emoji = '🌜';
    }

    final targetLang = languageLabelFromCode(state.targetLanguage);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kColorBorder),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kColorText,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Let's practice $targetLang",
                      style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Level display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kColorPrimary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      levelEmoji(state.proficiencyLevel),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are at level ${state.proficiencyLevel}!',
                        style: const TextStyle(
                          color: kColorText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelLabel(state.proficiencyLevel),
                        style: TextStyle(
                          color: kColorAccent.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // CTA with animated arrow
          const _AnimatedMenuCta(),
        ],
      ),
    );
  }
}

// ─── Translate Button ─────────────────────────────────────────────────────────
class _TranslateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TranslateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kColorAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: kColorAccent.withValues(alpha: 0.2),
          ),
        ),
        child: const Icon(
          Icons.translate_rounded,
          size: 18,
          color: kColorAccent,
        ),
      ),
    );
  }
}

// ─── Translation Bottom Sheet ─────────────────────────────────────────────────
class _TranslationSheet extends StatefulWidget {
  final String text;
  final AppStateModel model;

  const _TranslationSheet({required this.text, required this.model});

  @override
  State<_TranslationSheet> createState() => _TranslationSheetState();
}

class _TranslationSheetState extends State<_TranslationSheet> {
  bool _isLoading = true;
  String _translation = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
    final err = await widget.model.translateText(widget.text);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (err != null) {
          _error = err;
        } else {
          _translation = widget.model.translationResult;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kColorBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kColorAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate_rounded,
                      color: kColorAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Translation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kColorText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: kColorTextMuted, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Original text (collapsed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kColorBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
              ),
              child: Text(
                widget.text.length > 150
                    ? '${widget.text.substring(0, 150)}…'
                    : widget.text,
                style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Arrow
          const Icon(Icons.arrow_downward_rounded,
              color: kColorPrimary, size: 18),
          const SizedBox(height: 12),
          // Translation result
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kColorPrimary,
                          ),
                        ),
                      ),
                    )
                  : _error != null
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kColorError.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: kColorError, fontSize: 14),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kColorPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kColorPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: SelectableText(
                            _translation,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  height: 1.6,
                                  color: kColorText,
                                ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language Badge ───────────────────────────────────────────────────────────
class _LanguageBadge extends StatelessWidget {
  final String label;
  final bool isTarget;

  const _LanguageBadge({required this.label, this.isTarget = false});

  @override
  Widget build(BuildContext context) {
    final color = isTarget ? kColorAccent : kColorTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Example Card ─────────────────────────────────────────────────────────────
class _ExampleCard extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback? onTranslate;

  const _ExampleCard({
    required this.index,
    required this.text,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorPrimary.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: kColorPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
                const SizedBox(width: 8),
                if (onTranslate != null)
                  GestureDetector(
                    onTap: onTranslate,
                    child: Icon(Icons.translate_rounded,
                        size: 18,
                        color: kColorAccent.withValues(alpha: 0.5)),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded,
                    size: 20,
                    color: kColorTextMuted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Submit Button ───────────────────────────────────────────────────
class _AnimatedSubmitButton extends StatefulWidget {
  final bool isDisabled;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _AnimatedSubmitButton({
    required this.isDisabled,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  State<_AnimatedSubmitButton> createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<_AnimatedSubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: kPremiumCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    if (!widget.isDisabled) {
      HapticFeedback.lightImpact();
      _ctrl.forward();
    }
  }

  void _onTapUp(TapUpDetails d) async {
    if (!widget.isDisabled) {
      await _ctrl.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isSubmitting;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEnabled ? kPrimaryGradient : null,
            color: isEnabled ? null : kColorSurface,
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: null,
              splashColor: Colors.white30,
              highlightColor: Colors.white10,
              child: Center(
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEnabled
                                ? Icons.send_rounded
                                : Icons.send_outlined,
                            size: 20,
                            color: isEnabled ? Colors.white : kColorTextMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Submit Answer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? Colors.white : kColorTextMuted,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Next Question Button ─────────────────────────────────────────────────────
class _NextQuestionButton extends StatefulWidget {
  final VoidCallback onTap;
  final String previewText;

  const _NextQuestionButton({
    required this.onTap,
    required this.previewText,
  });

  @override
  State<_NextQuestionButton> createState() => _NextQuestionButtonState();
}

class _NextQuestionButtonState extends State<_NextQuestionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: kPremiumCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kColorPrimary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            color: kColorPrimary.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kColorPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            color: kColorPrimary, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Next Question',
                          style: TextStyle(
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
              const SizedBox(height: 10),
              Text(
                widget.previewText,
                style: const TextStyle(
                  color: kColorText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to answer',
                    style: TextStyle(
                      color: kColorPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.touch_app_rounded,
                      color: kColorPrimary.withValues(alpha: 0.8), size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated CTA Arrow ─────────────────────────────────────────────────────
class _AnimatedMenuCta extends StatefulWidget {
  const _AnimatedMenuCta();

  @override
  State<_AnimatedMenuCta> createState() => _AnimatedMenuCtaState();
}

class _AnimatedMenuCtaState extends State<_AnimatedMenuCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-0.25, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kColorAccent.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Animated arrow
          SlideTransition(
            position: _slideAnim,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open the menu',
                  style: TextStyle(
                    color: kColorText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose your first topic and start practicing!',
                  style: TextStyle(
                    color: kColorTextMuted.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}