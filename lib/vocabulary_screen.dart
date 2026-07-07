import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

const String _kPrefAskedWords = 'vocab_asked_words';

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
  final List<String> _askedWords = [];
  bool _isTtsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAskedWords();
  }

  Future<void> _loadAskedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kPrefAskedWords);
    if (saved != null) {
      _askedWords.addAll(saved);
    }
    if (mounted) _fetchNextVocabularyQuestion();
  }

  Future<void> _fetchNextVocabularyQuestion() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please enter your activation code first.');
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
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        askedWords: _askedWords,
      );
      if (mounted)
        setState(() {
          _question = q;
          _askedWords.add(q.word);
          _checkLevelLoop(state.proficiencyLevel);
          _saveAskedWords();
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

  void _checkLevelLoop(String level) {
    const pools = {'A1': 500, 'A2': 1000, 'B1': 2000, 'B2': 3000, 'C1': 4000};
    final maxWords = pools[level.toUpperCase()] ?? 2000;
    if (_askedWords.length >= maxWords) {
      _askedWords.clear();
    }
  }

  Future<void> _saveAskedWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefAskedWords, _askedWords);
  }

  Future<void> _speakWord() async {
    if (_question == null) return;
    setState(() => _isTtsLoading = true);
    try {
      final lang = context.read<AppStateModel>().targetLanguage;
      await _tts.setLanguage(ttsLocaleFor(lang));
      await _tts.speak(_question!.word);
    } finally {
      if (mounted) setState(() => _isTtsLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _maxWordsForLevel(String level) {
    const pools = {'A1': 500, 'A2': 1000, 'B1': 2000, 'B2': 3000, 'C1': 4000};
    return pools[level.toUpperCase()] ?? 2000;
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
        title: Text('Vocabulary',
            style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: isLight ? Colors.black87 : Colors.white),
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
                      _VocabularyProgressBar(
                        askedCount: _askedWords.length,
                        maxWords: _maxWordsForLevel(
                            context.read<AppStateModel>().proficiencyLevel),
                      ),
                      const SizedBox(height: 20),
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
                                  onTap: _isTtsLoading ? null : _speakWord,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _isTtsLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(
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
                                  color: bgColor ?? Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: borderColor ??
                                          cs.outline.withValues(alpha: 0.5)),
                                  boxShadow: isLight
                                      ? [BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text(opt,
                                            style: TextStyle(
                                                color: cs.onSurface,
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
                      if (_question!.exampleSentence.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.4)),
                              boxShadow: isLight
                                  ? [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))]
                                  : [],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.format_quote_rounded,
                                    size: 16,
                                    color: kColorPrimary.withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      _question!.exampleSentence,
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(alpha: 0.6),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                                    style: TextStyle(
                                        color: cs.onSurface, fontSize: 14),
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

class _VocabularyProgressBar extends StatelessWidget {
  final int askedCount;
  final int maxWords;
  const _VocabularyProgressBar({
    required this.askedCount,
    required this.maxWords,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cs = Theme.of(context).colorScheme;
    final progress = maxWords > 0 ? askedCount / maxWords : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Vocabulary Progress',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
            const Spacer(),
            Text(
              '$askedCount / $maxWords',
              style: TextStyle(
                color: kColorPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: isLight
                ? Colors.grey.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(kColorPrimary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

