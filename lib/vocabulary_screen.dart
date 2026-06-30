import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final GeminiApiService _api = GeminiApiService();
  bool _loading = false;
  VocabularyQuestion? _question;
  String? _selectedOption;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  Future<void> _generateQuestion() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please configure your API key first.');
      return;
    }
    setState(() {
      _loading = true;
      _question = null;
      _selectedOption = null;
      _isCorrect = null;
    });
    try {
      final q = await _api.generateVocabularyQuestion(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
      );
      if (mounted)
        setState(() {
          _question = q;
          _loading = false;
        });
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  void _selectOption(String option) {
    if (_isCorrect != null) return;
    setState(() {
      _selectedOption = option;
      _isCorrect = option == _question!.correctDefinition;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: kColorError,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Vocabulary',
            style: TextStyle(color: kColorText, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: kColorText),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kColorPrimary))
            : _question == null
                ? const SizedBox()
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: kPrimaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: kColorPrimary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('What does this word mean?',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                            const SizedBox(height: 12),
                            Text(_question!.word,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._question!.options.map((opt) {
                        Color? borderColor;
                        Color? bgColor;
                        if (_selectedOption != null) {
                          if (opt == _question!.correctDefinition) {
                            borderColor = const Color(0xFF2ECC71);
                            bgColor =
                                const Color(0xFF2ECC71).withValues(alpha: 0.1);
                          } else if (opt == _selectedOption && !_isCorrect!) {
                            borderColor = kColorError;
                            bgColor = kColorError.withValues(alpha: 0.1);
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _selectOption(opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: bgColor ?? kColorSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: borderColor ??
                                        kColorBorder.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(opt,
                                          style: const TextStyle(
                                              color: kColorText,
                                              fontSize: 15))),
                                  if (_selectedOption != null &&
                                      opt == _question!.correctDefinition)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF2ECC71), size: 22),
                                  if (_selectedOption == opt &&
                                      _isCorrect == false &&
                                      opt != _question!.correctDefinition)
                                    const Icon(Icons.cancel_rounded,
                                        color: kColorError, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_isCorrect != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (_isCorrect!
                                    ? const Color(0xFF2ECC71)
                                    : kColorError)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  _isCorrect!
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _isCorrect!
                                      ? const Color(0xFF2ECC71)
                                      : kColorError,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _isCorrect!
                                    ? '✓ Correct! The answer is: ${_question!.correctDefinition}'
                                    : '✗ The correct answer is: ${_question!.correctDefinition}',
                                style: const TextStyle(
                                    color: kColorText, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _NextButton(onTap: _generateQuestion),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Center(
            child: Text('Next Word',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700))),
      ),
    );
  }
}
