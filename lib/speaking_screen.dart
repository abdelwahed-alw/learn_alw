import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';
import 'string_utils.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final GeminiApiService _api = GeminiApiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _loading = false;
  bool _listening = false;
  bool _submitted = false;
  bool _speechAvailable = false;
  String? _targetSentence;
  String _recognizedText = '';
  int _matchPercent = 0;
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && status == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
    _generateSentence();
  }

  @override
  void dispose() {
    _speech.stop();
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
      _matchPercent = 0;
      _recognizedText = '';
    });
    try {
      final speak = await _api.generateSpeakingSentence(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
      );
      if (mounted)
        setState(() {
          _targetSentence = speak.sentence;
          _loading = false;
        });
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  String _sttLocaleFor(String code) {
    const map = {
      'ar': 'ar_SA',
      'en': 'en_US',
      'fr': 'fr_FR',
      'es': 'es_ES',
      'de': 'de_DE',
      'tr': 'tr_TR',
      'it': 'it_IT',
      'pt': 'pt_PT',
      'zh': 'zh_CN',
      'ja': 'ja_JP',
    };
    return map[code] ?? 'en_US';
  }

  Future<void> _startListening() async {
    if (_targetSentence == null) return;
    if (!_speechAvailable) {
      _showError('Speech recognition not available on this device.');
      return;
    }
    if (_speech.isListening) return;
    final lang = context.read<AppStateModel>().targetLanguage;
    setState(() {
      _listening = true;
      _recognizedText = '';
      _submitted = false;
      _matchPercent = 0;
    });
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: _sttLocaleFor(lang),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted && _targetSentence != null) {
      final pct = similarityPercent(_recognizedText, _targetSentence!);
      setState(() {
        _listening = false;
        _submitted = true;
        _matchPercent = pct;
      });
    }
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
        title: const Text('Speaking',
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
                  if (_targetSentence != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('Say this sentence:',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(_targetSentence!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTapDown: _listening ? null : (_) => _startListening(),
                      onTapUp: _listening ? (_) => _stopListening() : null,
                      onTapCancel: _listening ? _stopListening : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _listening ? kPrimaryGradient : null,
                          color: _listening ? null : kColorSurface,
                          boxShadow: [
                            BoxShadow(
                              color: _listening
                                  ? kColorPrimary.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.2),
                              blurRadius: _listening ? 30 : 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _listening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: _listening ? Colors.white : kColorPrimary,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _listening ? 'Release to check' : 'Hold to speak',
                      style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.7),
                          fontSize: 13),
                    ),
                    if (_recognizedText.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kColorSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kColorBorder.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('You said:',
                                style: TextStyle(
                                    color: kColorTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(_recognizedText,
                                style: const TextStyle(
                                    color: kColorText, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                    if (_submitted) ...[
                      const SizedBox(height: 16),
                      _SpeakingFeedbackCard(
                        matchPercent: _matchPercent,
                      ),
                      const SizedBox(height: 20),
                      _NextButton(onTap: _generateSentence),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _SpeakingFeedbackCard extends StatelessWidget {
  final int matchPercent;
  const _SpeakingFeedbackCard({required this.matchPercent});

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
