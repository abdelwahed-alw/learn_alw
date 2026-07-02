import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  bool _loading = false;
  VocabularyQuestion? _question;
  String? _selectedOption;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _fetchNextVocabularyQuestion();
  }

  Future<void> _fetchNextVocabularyQuestion() async {
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
      final q = await _api.generateVocabularyQuestionForLevel(
        apiKey: state.apiKey,
        userLevel: state.proficiencyLevel,
        categoryName: state.selectedTopic,
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

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _selectOption(String option) {
    if (_isCorrect != null) return;
    setState(() {
      _selectedOption = option;
      _isCorrect = option == _question!.correctOption;
    });
    context.read<AppStateModel>().incrementCategoryProgress('vocabulary');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _fetchNextVocabularyQuestion();
    });
  }

  Future<void> _speakWord() async {
    if (_question == null) return;
    await _tts.setLanguage('en-US');
    await _tts.speak(_question!.word);
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
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text('What does this word mean?',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_question!.word,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5)),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _speakWord,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._question!.options.map((opt) {
                        Color? borderColor;
                        Color? bgColor;
                        if (_selectedOption != null) {
                          if (opt == _question!.correctOption) {
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
                                      opt == _question!.correctOption)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF2ECC71), size: 22),
                                  if (_selectedOption == opt &&
                                      _isCorrect == false &&
                                      opt != _question!.correctOption)
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                    _isCorrect!
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: _isCorrect!
                                        ? const Color(0xFF2ECC71)
                                        : kColorError,
                                    size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    _isCorrect!
                                        ? 'Correct! The answer is: ${_question!.correctOption}'
                                        : 'The correct answer is: ${_question!.correctOption}',
                                    style: const TextStyle(
                                        color: kColorText, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}


