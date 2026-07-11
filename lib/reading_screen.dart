import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  bool _loading = false;
  ReadingExercise? _exercise;
  String? _selectedOption;
  bool? _isCorrect;
  bool _showTranslation = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _generateExercise();
  }

  Future<void> _generateExercise() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('configureApiKeyFirst'.tr());
      return;
    }
    setState(() {
      _loading = true;
      _exercise = null;
      _selectedOption = null;
      _isCorrect = null;
      _showTranslation = false;
    });
    try {
      final rng = Random();
      final name = readingNames[rng.nextInt(readingNames.length)];
      final theme = readingThemes[rng.nextInt(readingThemes.length)];
      final seed = DateTime.now().millisecondsSinceEpoch.toString();
      final ex = await _api.generateReadingExercise(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        userLevel: state.proficiencyLevel,
        characterName: name,
        storyTheme: theme,
        seed: seed,
      );
      if (mounted) {
        ex.options.shuffle();
        setState(() {
          _exercise = ex;
          _loading = false;
        });
      }
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

  Future<void> _speakPassage() async {
    if (_exercise == null) return;
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    final lang = context.read<AppStateModel>().targetLanguage;
    await _tts.setLanguage(ttsLocaleFor(lang));
    await _tts.speak(_exercise!.passage);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _selectOption(String option) {
    if (_isCorrect != null) return;
    setState(() {
      _selectedOption = option;
      _isCorrect = option == _exercise!.correctAnswer;
    });
    context.read<AppStateModel>().incrementCategoryProgress('reading');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('reading'.tr(),
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: cs.outline.withValues(alpha: 0.5)),
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
                                GestureDetector(
                                  onTap: _speakPassage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _isSpeaking
                                          ? kColorPrimary.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _isSpeaking
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_up_outlined,
                                      size: 18,
                                      color: _isSpeaking
                                          ? kColorPrimary
                                          : cs.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('readingPassage'.tr(),
                                    style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _showTranslation = !_showTranslation),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _showTranslation
                                          ? kColorPrimary.withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _showTranslation
                                            ? kColorPrimary.withValues(
                                                alpha: 0.4)
                                            : cs.outline.withValues(
                                                alpha: 0.5),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.translate_rounded,
                                      size: 18,
                                      color: _showTranslation
                                          ? kColorPrimary
                                          : cs.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> a) =>
                                      FadeTransition(opacity: a, child: child),
                              child: _showTranslation
                                  ? Text(
                                      _exercise!.passageTranslation.isEmpty
                                          ? _exercise!.passage
                                          : _exercise!.passageTranslation,
                                      key: const ValueKey('translation'),
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                          color: cs.onSurface,
                                          fontSize: 15,
                                          height: 1.7),
                                    )
                                  : Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        _exercise!.passage,
                                        key: const ValueKey('original'),
                                        style: TextStyle(
                                            color: cs.onSurface,
                                            fontSize: 15,
                                            height: 1.7),
                                      ),
                                    ),
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
                                color: bgColor ?? Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: borderColor ??
                                        cs.outline.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(opt,
                                          style: TextStyle(
                                              color: cs.onSurface,
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
            child: Center(
                child: Text('nextPassage'.tr(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700))),
      ),
    );
  }
}
