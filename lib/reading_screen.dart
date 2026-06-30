import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final GeminiApiService _api = GeminiApiService();
  bool _loading = false;
  ReadingExercise? _exercise;
  String? _selectedOption;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _generateExercise();
  }

  Future<void> _generateExercise() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please configure your API key first.');
      return;
    }
    setState(() {
      _loading = true;
      _exercise = null;
      _selectedOption = null;
      _isCorrect = null;
    });
    try {
      final ex = await _api.generateReadingExercise(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
      );
      if (mounted)
        setState(() {
          _exercise = ex;
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
      _isCorrect = option == _exercise!.correctAnswer;
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
        title: const Text('Reading',
            style: TextStyle(color: kColorText, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: kColorText),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
          : _exercise == null
              ? const SizedBox()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kColorSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: kColorBorder.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color:
                                          kColorPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.auto_stories_rounded,
                                      color: kColorPrimary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text('Reading Passage',
                                    style: TextStyle(
                                        color: kColorText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _exercise!.passage,
                              style: const TextStyle(
                                  color: kColorText, fontSize: 15, height: 1.7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: kPrimaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: kColorPrimary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                          _exercise!.question,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._exercise!.options.map((opt) {
                        Color? borderColor;
                        Color? bgColor;
                        if (_selectedOption != null) {
                          if (opt == _exercise!.correctAnswer) {
                            borderColor = const Color(0xFF2ECC71);
                            bgColor =
                                const Color(0xFF2ECC71).withValues(alpha: 0.1);
                          } else if (opt == _selectedOption && !_isCorrect!) {
                            borderColor = kColorError;
                            bgColor = kColorError.withValues(alpha: 0.1);
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _selectOption(opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bgColor ?? kColorSurface,
                                borderRadius: BorderRadius.circular(12),
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
                                              fontSize: 14))),
                                  if (_selectedOption != null &&
                                      opt == _exercise!.correctAnswer)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF2ECC71), size: 22),
                                  if (_selectedOption == opt &&
                                      _isCorrect == false &&
                                      opt != _exercise!.correctAnswer)
                                    const Icon(Icons.cancel_rounded,
                                        color: kColorError, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_isCorrect != null) ...[
                        const SizedBox(height: 16),
                        _NextButton(onTap: _generateExercise),
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
            child: Text('Next Passage',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700))),
      ),
    );
  }
}
