import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';
import 'string_utils.dart';

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
  bool _playingSlow = false;
  bool _submitted = false;
  bool _isInputEmpty = true;
  String? _targetSentence;
  int _matchPercent = 0;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted)
        setState(() {
          _playing = false;
          _playingSlow = false;
        });
    });
    _tts.setErrorHandler((_) {
      if (mounted)
        setState(() {
          _playing = false;
          _playingSlow = false;
        });
    });
    _generateSentence();
  }

  @override
  void dispose() {
    _tts.stop();
    _answerController.dispose();
    super.dispose();
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
      _isInputEmpty = true;
      _matchPercent = 0;
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
        await _tts.setLanguage(ttsLocaleFor(state.targetLanguage));
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  Future<void> _playAudio() async {
    if (_targetSentence == null || _playing || _playingSlow) return;
    setState(() => _playing = true);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(_targetSentence!);
  }

  Future<void> _playAudioSlowly() async {
    if (_targetSentence == null || _playing || _playingSlow) return;
    setState(() => _playingSlow = true);
    await _tts.setSpeechRate(0.2);
    await _tts.speak(_targetSentence!);
  }

  void _submitAnswer() {
    if (_targetSentence == null) return;
    final pct = similarityPercent(
      _answerController.text,
      _targetSentence!,
    );
    setState(() {
      _submitted = true;
      _matchPercent = pct;
    });
    context.read<AppStateModel>().incrementCategoryProgress('listening');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    _playing
                        ? 'Playing...'
                        : _playingSlow
                            ? 'Playing slowly...'
                            : 'Tap to play audio',
                    style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _playAudioSlowly,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _playingSlow
                            ? kColorAccent.withValues(alpha: 0.2)
                            : kColorSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kColorAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _playingSlow
                                ? Icons.volume_up_rounded
                                : Icons.speed_rounded,
                            size: 18,
                            color:
                                _playingSlow ? kColorAccent : kColorTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '0.5x',
                            style: TextStyle(
                              color:
                                  _playingSlow ? kColorAccent : kColorTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  TextField(
                    controller: _answerController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    enabled: !_submitted,
                    onChanged: (v) => setState(() => _isInputEmpty = v.trim().isEmpty),
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
                      onTap: _isInputEmpty ? null : _submitAnswer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _isInputEmpty ? null : kPrimaryGradient,
                          color: _isInputEmpty ? kColorSurface : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Check Answer',
                              style: TextStyle(
                                color: _isInputEmpty
                                    ? kColorTextMuted
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ),
                  if (_submitted) ...[
                    _FeedbackCard(
                      matchPercent: _matchPercent,
                      targetSentence: _targetSentence!,
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

class _FeedbackCard extends StatelessWidget {
  final int matchPercent;
  final String targetSentence;
  const _FeedbackCard({
    required this.matchPercent,
    required this.targetSentence,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = matchFeedback(matchPercent);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Match: $matchPercent%',
              style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('The sentence was: $targetSentence',
              style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.8), fontSize: 14)),
        ],
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
