import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/config.dart';
import '../../core/languages.dart';
import '../../core/localization.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../widgets/cards.dart';
import 'home_screen.dart';

class ProficiencyTestScreen extends StatefulWidget {
  const ProficiencyTestScreen({super.key});

  @override
  State<ProficiencyTestScreen> createState() => _ProficiencyTestScreenState();
}

class _ProficiencyTestScreenState extends State<ProficiencyTestScreen> {
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

    final result = await model.getTestQuestion(
      questionNumber: _questionNumber,
      totalQuestions: _totalQuestions,
      previousQA: _qaHistory,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.error != null) {
          _errorMessage = result.error;
        } else {
          _currentMcq = result.question;
        }
      });
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

    final result = await model.runProficiencyTest(qaHistory: _qaHistory);

    if (mounted) {
      if (result.error != null) {
        setState(() {
          _errorMessage = result.error;
          _isEvaluating = false;
        });
        return;
      }

      await model.completeOnboarding();
      if (mounted) {
        setState(() {
          _resultLevel = result.result!.level;
          _resultReasoning = result.result!.reasoning;
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
    final lang = context.watch<AppStateModel>().nativeLanguage;
    return Scaffold(
      backgroundColor: kColorBackground,
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  kColorPrimary.withValues(alpha: 0.12),
                  kColorPrimary.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          SafeArea(
            child: _resultLevel != null
                ? _buildResultView(lang)
                : _buildTestView(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildTestView(String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
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
                child: Text(t('placementTest', lang),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
              ),
              if (_currentMcq != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: kColorPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(_currentMcq!.level,
                      style: const TextStyle(
                          color: kColorPrimary, fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressBar(lang),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading || _isEvaluating
                ? _buildLoadingState(lang)
                : _errorMessage != null
                    ? _buildErrorState(lang)
                    : _buildQuestionArea(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String lang) {
    final progress = _qaHistory.length / _totalQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${t('question', lang)} $_questionNumber ${t('of', lang)} $_totalQuestions',
              style: const TextStyle(
                  color: kColorTextMuted, fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              '${(_qaHistory.length * 100 ~/ _totalQuestions)}%',
              style: TextStyle(
                  color: kColorPrimary.withValues(alpha: 0.8),
                  fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildLoadingState(String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3, color: kColorPrimary,
              backgroundColor: kColorSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isEvaluating
                ? t('analyzingProficiency', lang)
                : t('generatingQuestion', lang),
            style: const TextStyle(
                color: kColorTextMuted, fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: kColorError, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kColorTextMuted, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _generateNextQuestion,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t('tryAgain', lang),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(String lang) {
    if (_currentMcq == null) return const SizedBox.shrink();

    final hasSelected = _selectedOptionIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: kCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${t('question', lang)} $_questionNumber',
                    style: const TextStyle(
                        color: kColorPrimary, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Text(_currentMcq!.question,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 17, height: 1.5,
                        fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _currentMcq!.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = _currentMcq!.options[index];
              final isSelected = _selectedOptionIndex == index;
              return McqOptionTile(
                label: String.fromCharCode(65 + index),
                text: option,
                isSelected: isSelected,
                onTap: () => _selectOption(index),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: hasSelected ? _submitAnswer : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              gradient: hasSelected ? kPrimaryGradient : null,
              color: hasSelected ? null : kColorSurface,
              borderRadius: BorderRadius.circular(14),
              border: hasSelected ? null : Border.all(color: kColorBorder),
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
                    ? t('submitGetResults', lang)
                    : t('nextQuestion', lang),
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

  Widget _buildResultView(String lang) {
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
              Text(levelEmoji(_resultLevel!),
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(t('yourLevel', lang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kColorTextMuted,
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 8),
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
                  '${_resultLevel!} — ${tLevel(_resultLevel!, lang)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),
              Text('$correctCount / $_totalQuestions ${t('correct', lang)}',
                  style: const TextStyle(
                      color: kColorAccent, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              if (_resultReasoning != null && _resultReasoning!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kColorSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kColorBorder),
                  ),
                  child: Text(_resultReasoning!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: kColorAccent,
                            height: 1.5,
                          )),
                ),
              const SizedBox(height: 32),
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
                  child: Center(
                    child: Text(t('startLearningArrow', lang),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700)),
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
