// lib/proficiency_test_screen.dart
// Dynamic 5-question MCQ proficiency assessment powered by Gemini.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';
import 'home_screen.dart';

class ProficiencyTestScreen extends StatefulWidget {
  const ProficiencyTestScreen({super.key});

  @override
  State<ProficiencyTestScreen> createState() => _ProficiencyTestScreenState();
}

class _ProficiencyTestScreenState extends State<ProficiencyTestScreen> {
  final GeminiApiService _api = GeminiApiService();

  static const int _totalQuestions = 5;

  final List<Map<String, dynamic>> _qaHistory = [];
  McqQuestion? _currentMcq;
  int? _selectedOptionIndex;
  bool _isLoading = false;
  bool _isEvaluating = false;
  String? _resultLevel;
  String? _resultReasoning;
  String? _errorMessage;

  int get _questionNumber => _qaHistory.length + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateNextQuestion());
  }

  Future<void> _generateNextQuestion() async {
    final model = context.read<AppStateModel>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedOptionIndex = null;
      _currentMcq = null;
    });

    try {
      final mcq = await _api.generateTestQuestion(
        apiKey: model.apiKey,
        targetLanguage: languageLabelFromCode(model.targetLanguage),
        nativeLanguage: languageLabelFromCode(model.nativeLanguage),
        questionNumber: _questionNumber,
        totalQuestions: _totalQuestions,
        previousQA: _qaHistory,
      );
      if (mounted) {
        setState(() {
          _currentMcq = mcq;
          _isLoading = false;
        });
      }
    } on GeminiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    }
  }

  void _selectOption(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedOptionIndex = index);
  }

  Future<void> _submitAnswer() async {
    if (_selectedOptionIndex == null || _currentMcq == null) return;

    HapticFeedback.mediumImpact();
    final selected = _currentMcq!.options[_selectedOptionIndex!];

    _qaHistory.add({
      'question': _currentMcq!.question,
      'options': _currentMcq!.options,
      'correct_answer': _currentMcq!.correctAnswer,
      'selected': selected,
      'level': _currentMcq!.level,
    });

    if (_qaHistory.length >= _totalQuestions) {
      await _evaluateResults();
    } else {
      await _generateNextQuestion();
    }
  }

  Future<void> _evaluateResults() async {
    final model = context.read<AppStateModel>();
    setState(() => _isEvaluating = true);

    try {
      final result = await _api.evaluateProficiency(
        apiKey: model.apiKey,
        targetLanguage: languageLabelFromCode(model.targetLanguage),
        nativeLanguage: languageLabelFromCode(model.nativeLanguage),
        qaHistory: _qaHistory,
      );

      await model.setProficiencyLevel(result.level);
      await model.completeOnboarding();

      if (mounted) {
        setState(() {
          _resultLevel = result.level;
          _resultReasoning = result.reasoning;
          _isEvaluating = false;
        });
      }
    } on GeminiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isEvaluating = false;
        });
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: kPremiumCurve),
          child: child,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kColorPrimary.withValues(alpha: 0.12),
                    kColorPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _resultLevel != null
                ? _buildResultView()
                : _buildTestView(),
          ),
        ],
      ),
    );
  }

  // ── Test View ─────────────────────────────────────────────────────────────
  Widget _buildTestView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kColorSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kColorBorder),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: kColorText, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Placement Test',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              // Difficulty badge
              if (_currentMcq != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: kColorPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _currentMcq!.level,
                    style: const TextStyle(
                      color: kColorPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 32),
          // Content
          Expanded(
            child: _isLoading || _isEvaluating
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildQuestionArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _qaHistory.length / _totalQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $_questionNumber of $_totalQuestions',
              style: const TextStyle(
                color: kColorTextMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(_qaHistory.length * 100 ~/ _totalQuestions)}%',
              style: TextStyle(
                color: kColorPrimary.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: kColorPrimary,
              backgroundColor: kColorSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isEvaluating
                ? 'Analyzing your proficiency…'
                : 'Generating question…',
            style: const TextStyle(
              color: kColorTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: kColorError, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kColorTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _generateNextQuestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea() {
    if (_currentMcq == null) return const SizedBox.shrink();

    final hasSelected = _selectedOptionIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: kCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorBorder),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question $_questionNumber',
                  style: const TextStyle(
                    color: kColorPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentMcq!.question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // MCQ Options
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _currentMcq!.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = _currentMcq!.options[index];
              final isSelected = _selectedOptionIndex == index;
              return _McqOptionTile(
                label: String.fromCharCode(65 + index), // A, B, C, D
                text: option,
                isSelected: isSelected,
                onTap: () => _selectOption(index),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Next / Submit button
        GestureDetector(
          onTap: hasSelected ? _submitAnswer : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              gradient: hasSelected ? kPrimaryGradient : null,
              color: hasSelected ? null : kColorSurface,
              borderRadius: BorderRadius.circular(14),
              border: hasSelected
                  ? null
                  : Border.all(color: kColorBorder),
              boxShadow: hasSelected
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
              child: Text(
                _questionNumber >= _totalQuestions
                    ? 'Submit & Get Results'
                    : 'Next Question →',
                style: TextStyle(
                  color: hasSelected ? Colors.white : kColorTextMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Result View ───────────────────────────────────────────────────────────
  Widget _buildResultView() {
    // Count correct answers
    final correctCount = _qaHistory.where((qa) {
      return qa['selected'] == qa['correct_answer'];
    }).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: kPremiumCurve,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Level emoji big
              Text(
                levelEmoji(_resultLevel!),
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: kColorTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '${_resultLevel!} — ${levelLabel(_resultLevel!)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Score
              Text(
                '$correctCount / $_totalQuestions correct',
                style: const TextStyle(
                  color: kColorAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Reasoning
              if (_resultReasoning != null && _resultReasoning!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kColorSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kColorBorder),
                  ),
                  child: Text(
                    _resultReasoning!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kColorAccent,
                          height: 1.5,
                        ),
                  ),
                ),
              const SizedBox(height: 32),
              // Continue button
              GestureDetector(
                onTap: _navigateToHome,
                child: Container(
                  width: double.infinity,
                  height: 52,
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
                  child: const Center(
                    child: Text(
                      'Start Learning →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MCQ Option Tile ──────────────────────────────────────────────────────────
class _McqOptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _McqOptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? kColorPrimary.withValues(alpha: 0.1)
              : kColorSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? kColorPrimary.withValues(alpha: 0.5)
                : kColorBorder.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isSelected ? kPrimaryGradient : null,
                color: isSelected ? null : kColorBackground,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: kColorBorder),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : kColorTextMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? kColorText : kColorAccent,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  gradient: kPrimaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 13, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
