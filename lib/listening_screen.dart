import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final GeminiApiService _api = GeminiApiService();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _answerController = TextEditingController();
  bool _loading = false;
  bool _playing = false;
  bool _submitted = false;
  String? _targetSentence;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _playing = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _playing = false);
    });
    _generateSentence();
  }

  @override
  void dispose() {
    _tts.stop();
    _answerController.dispose();
    super.dispose();
  }

  String _ttsLocaleFor(String code) {
    const map = {
      'ar': 'ar-SA',
      'en': 'en-US',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'de': 'de-DE',
      'tr': 'tr-TR',
      'it': 'it-IT',
      'pt': 'pt-PT',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
    };
    return map[code] ?? 'en-US';
  }

  Future<void> _generateSentence() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please configure your API key first.');
      return;
    }
    setState(() {
      _loading = true;
      _targetSentence = null;
      _submitted = false;
      _isCorrect = null;
      _answerController.clear();
    });
    try {
      final dict = await _api.generateDictationSentence(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
      );
      if (mounted) {
        setState(() {
          _targetSentence = dict.sentence;
          _loading = false;
        });
        await _tts.setLanguage(_ttsLocaleFor(state.targetLanguage));
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  Future<void> _playAudio() async {
    if (_targetSentence == null || _playing) return;
    setState(() => _playing = true);
    await _tts.speak(_targetSentence!);
  }

  void _submitAnswer() {
    if (_targetSentence == null) return;
    final answer = _answerController.text.trim().toLowerCase();
    final target = _targetSentence!.trim().toLowerCase();
    final normalize = (String s) => s
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final correct = normalize(answer) == normalize(target);
    setState(() {
      _submitted = true;
      _isCorrect = correct;
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
        title: const Text('Listening',
            style: TextStyle(color: kColorText, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: kColorText),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorPrimary.withValues(alpha: 0.1),
                    ),
                    child: GestureDetector(
                      onTap: _playAudio,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _playing ? kPrimaryGradient : null,
                          color: _playing ? null : kColorSurface,
                          boxShadow: _playing
                              ? [
                                  BoxShadow(
                                      color:
                                          kColorPrimary.withValues(alpha: 0.4),
                                      blurRadius: 20)
                                ]
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10)
                                ],
                        ),
                        child: Icon(
                          _playing
                              ? Icons.volume_up_rounded
                              : Icons.play_arrow_rounded,
                          color: _playing ? Colors.white : kColorPrimary,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _playing ? 'Playing...' : 'Tap to play audio',
                    style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const Spacer(flex: 1),
                  TextField(
                    controller: _answerController,
                    enabled: !_submitted,
                    decoration: InputDecoration(
                      hintText: 'Type what you heard...',
                      filled: true,
                      fillColor: kColorSurface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_submitted)
                    GestureDetector(
                      onTap: _answerController.text.trim().isEmpty
                          ? null
                          : _submitAnswer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _answerController.text.trim().isEmpty
                              ? null
                              : kPrimaryGradient,
                          color: _answerController.text.trim().isEmpty
                              ? kColorSurface
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Check Answer',
                              style: TextStyle(
                                color: _answerController.text.trim().isEmpty
                                    ? kColorTextMuted
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ),
                  if (_submitted) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_isCorrect!
                                ? const Color(0xFF2ECC71)
                                : kColorError)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: (_isCorrect!
                                    ? const Color(0xFF2ECC71)
                                    : kColorError)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  _isCorrect!
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _isCorrect!
                                      ? const Color(0xFF2ECC71)
                                      : kColorError,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(_isCorrect! ? 'Correct!' : 'Not quite',
                                  style: TextStyle(
                                      color: _isCorrect!
                                          ? const Color(0xFF2ECC71)
                                          : kColorError,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('The sentence was: $_targetSentence',
                              style: TextStyle(
                                  color: kColorTextMuted.withValues(alpha: 0.8),
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NextButton(onTap: _generateSentence),
                  ],
                  const Spacer(flex: 1),
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
            child: Text('New Sentence',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700))),
      ),
    );
  }
}
