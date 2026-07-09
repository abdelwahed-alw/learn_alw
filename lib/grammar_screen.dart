import 'dart:math';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final TextEditingController _answerController = TextEditingController();
  final GeminiApiService _api = GeminiApiService();
  bool _loading = false;
  bool _submitting = false;
  GrammarQuestion? _question;
  GrammarFeedback? _feedback;
  String? _selectedOption;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _generateQuestion() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please enter your activation code first.');
      return;
    }
    setState(() {
      _loading = true;
      _question = null;
      _feedback = null;
      _selectedOption = null;
      _answerController.clear();
    });
    try {
      final rng = Random();
      final selectedTopic =
          grammarTopics[rng.nextInt(grammarTopics.length)];
      final seed = DateTime.now().millisecondsSinceEpoch.toString();
      final question = await _api.generateGrammarQuestion(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        grammarTopic: selectedTopic,
        seed: seed,
      );
      if (mounted) {
        setState(() {
          _question = question;
          _loading = false;
        });
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final state = context.read<AppStateModel>();
    setState(() => _submitting = true);
    try {
      final feedback = await _api.evaluateGrammar(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        sentence: _question!.sentence,
        correctAnswer: _question!.correctAnswer,
        userAnswer: answer,
        explanation: _question!.explanation,
      );
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _submitting = false;
        });
        context.read<AppStateModel>().incrementCategoryProgress('grammar');
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _submitting = false);
    }
  }

  void _selectOption(String option) {
    if (_feedback != null || _submitting) return;
    setState(() => _selectedOption = option);
    _answerController.text = option;
    _submitAnswer();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Grammar Exercise',
          style: TextStyle(
            color: isLight ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isLight ? Colors.black87 : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_question != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.text_fields_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _question!.type == 'error_correction'
                                      ? 'Find the Error'
                                      : 'Fill in the Blank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                _question!.sentence,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_question!.type == 'fill_blank' &&
                          _question!.options != null) ...[
                        Text(
                          'Choose the correct option:',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._question!.options!.map(
                          (option) {
                            final isSelected = option == _selectedOption;
                            final isCorrectAnswer =
                                option == _question!.correctAnswer;
                            Color? borderColor;
                            Color? bgColor;
                            if (_feedback != null) {
                              if (isCorrectAnswer) {
                                borderColor = const Color(0xFF2ECC71);
                                bgColor = const Color(0xFF2ECC71)
                                    .withValues(alpha: 0.1);
                              } else if (isSelected && !_feedback!.isCorrect) {
                                borderColor = kColorError;
                                bgColor = kColorError.withValues(alpha: 0.1);
                              }
                            } else if (isSelected) {
                              borderColor = kColorPrimary;
                              bgColor = kColorPrimary.withValues(alpha: 0.08);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: (_feedback != null || _submitting)
                                    ? null
                                    : () => _selectOption(option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: bgColor ?? Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor ??
                                          cs.outline.withValues(alpha: 0.5),
                                    ),
                                    boxShadow: isLight
                                        ? [BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2))]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 20,
                                        color: _feedback != null &&
                                                isCorrectAnswer
                                            ? const Color(0xFF2ECC71)
                                            : _feedback != null &&
                                                    isSelected &&
                                                    !_feedback!.isCorrect
                                                ? kColorError
                                                : isSelected
                                                    ? kColorPrimary
                                                    : cs.onSurface
                                                        .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              color: cs.onSurface,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_submitting && isSelected)
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: kColorPrimary),
                                        ),
                                      if (_feedback != null && isCorrectAnswer)
                                        const Icon(Icons.check_circle_rounded,
                                            color: Color(0xFF2ECC71), size: 22),
                                      if (_feedback != null &&
                                          isSelected &&
                                          !_feedback!.isCorrect)
                                        const Icon(Icons.cancel_rounded,
                                            color: kColorError, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        TextField(
                          controller: _answerController,
                          maxLines: 3,
                          readOnly: _feedback != null,
                          decoration: InputDecoration(
                            hintText: 'Type the corrected sentence...',
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AnimatedButton(
                          isLoading: _submitting,
                          label: 'submitAnswer'.tr(),
                          onTap: _feedback != null ? null : _submitAnswer,
                        ),
                      ],
                      if (_feedback != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (_feedback!.isCorrect
                                    ? const Color(0xFF2ECC71)
                                    : kColorError)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (_feedback!.isCorrect
                                      ? const Color(0xFF2ECC71)
                                      : kColorError)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _feedback!.isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: _feedback!.isCorrect
                                        ? const Color(0xFF2ECC71)
                                        : kColorError,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _feedback!.isCorrect
                                        ? 'Correct!'
                                        : 'Not quite',
                                    style: TextStyle(
                                      color: _feedback!.isCorrect
                                          ? const Color(0xFF2ECC71)
                                          : kColorError,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _feedback!.feedback,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_question!.explanation.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kColorAccent.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kColorAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Grammar Rule:',
                                  style: TextStyle(
                                    color: kColorAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _question!.explanation,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color:
                                        kColorTextMuted.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _AnimatedButton(
                          isLoading: false,
                          label: 'Next Question',
                          onTap: _generateQuestion,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8E53).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.text_fields_rounded,
                          size: 48,
                          color: Color(0xFFFF8E53),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Grammar Practice',
                        style: TextStyle(
                          color: kColorText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test your grammar with error correction\nand fill-in-the-blank exercises.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _AnimatedButton(
                        isLoading: _loading,
                        label: 'Start Exercise',
                        onTap: _generateQuestion,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onTap;

  const _AnimatedButton({
    required this.isLoading,
    required this.label,
    this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled ? kPrimaryGradient : null,
          color: enabled ? null : kColorSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: enabled ? Colors.white : kColorTextMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
