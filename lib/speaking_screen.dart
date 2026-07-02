import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

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
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _loading = false;
  bool _transcribing = false;
  bool _recording = false;
  String? _targetSentence;
  String _recognizedText = '';
  int _matchPercent = 0;
  bool _isPlayingMyVoice = false;
  bool _isPlayingTts = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingMyVoice = false);
    });
    _generateSentence();
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
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
      _recognizedText = '';
      _matchPercent = 0;
      _isPlayingMyVoice = false;
      _isPlayingTts = false;
      _recordedFilePath = null;
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

  Future<void> _startRecording() async {
    if (_targetSentence == null) return;
    setState(() {
      _recording = true;
      _recognizedText = '';
      _matchPercent = 0;
      _isPlayingMyVoice = false;
      _isPlayingTts = false;
      _recordedFilePath = null;
    });
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        setState(() => _recording = false);
        _showError('Microphone permission is required.');
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
      _recordedFilePath = filePath;
    } catch (e) {
      if (mounted) {
        setState(() => _recording = false);
        _showError('Mic Error: ${e.toString()}');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    setState(() => _recording = false);

    String? recPath;
    try {
      recPath = await _audioRecorder.stop();
    } catch (_) {
    }

    final path = recPath ?? _recordedFilePath;
    if (path == null || !File(path).existsSync()) {
      if (mounted) _showError('Recording failed.');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    final state = context.read<AppStateModel>();
    setState(() => _transcribing = true);
    try {
      final audioBytes = await File(path).readAsBytes();
      final transcription = await _api.transcribeAudio(
        apiKey: state.apiKey,
        audioBytes: audioBytes,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
      );
      if (mounted) {
        setState(() {
          _recordedFilePath = path;
          _recognizedText = transcription;
          if (_targetSentence != null) {
            _matchPercent =
                similarityPercent(transcription, _targetSentence!);
          }
          _transcribing = false;
        });
        context.read<AppStateModel>().incrementCategoryProgress('speaking');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _transcribing = false);
        _showError('Transcription failed. Try again.');
      }
    }
  }

  Future<void> _playMyVoice() async {
    if (_recordedFilePath == null) return;
    setState(() {
      _isPlayingMyVoice = true;
      _isPlayingTts = false;
    });
    await _tts.stop();
    await _audioPlayer.stop();
    try {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    } catch (e) {
      if (mounted) {
        setState(() => _isPlayingMyVoice = false);
        _showError('Could not play your voice.');
      }
    }
  }

  Future<void> _playCorrectPronunciation() async {
    if (_targetSentence == null) return;
    setState(() {
      _isPlayingTts = true;
      _isPlayingMyVoice = false;
    });
    await _audioPlayer.stop();
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(_targetSentence!);
    if (mounted) setState(() => _isPlayingTts = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Directionality(
              textDirection: TextDirection.ltr, child: Text(msg)),
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
                    _transcribing
                        ? const Column(
                            children: [
                              CircularProgressIndicator(
                                  color: kColorPrimary),
                              SizedBox(height: 12),
                              Text('Transcribing…',
                                  style: TextStyle(
                                      color: kColorTextMuted, fontSize: 13)),
                            ],
                          )
                        : Listener(
                            onPointerDown: _recording
                                ? null
                                : (event) => _startRecording(),
                            onPointerUp: _recording
                                ? (event) => _stopRecording()
                                : null,
                            onPointerCancel: _recording
                                ? (event) => _stopRecording()
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    _recording ? kPrimaryGradient : null,
                                color: _recording ? null : kColorSurface,
                                boxShadow: [
                                  BoxShadow(
                                    color: _recording
                                        ? kColorPrimary
                                            .withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.2),
                                    blurRadius: _recording ? 30 : 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _recording
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                color: _recording
                                    ? Colors.white
                                    : kColorPrimary,
                                size: 48,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    Text(
                      _transcribing
                          ? 'Transcribing…'
                          : _recording
                              ? 'Release to check'
                              : 'Hold to speak',
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
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: const Text('You said:',
                                  style: TextStyle(
                                      color: kColorTextMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 6),
                            Text(_recognizedText,
                                style: const TextStyle(
                                    color: kColorText, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SpeakingFeedbackCard(
                        matchPercent: _matchPercent,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  _isPlayingMyVoice ? null : _playMyVoice,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isPlayingMyVoice
                                      ? kColorPrimary.withValues(alpha: 0.15)
                                      : kColorSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isPlayingMyVoice
                                        ? kColorPrimary.withValues(alpha: 0.4)
                                        : kColorBorder.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlayingMyVoice
                                          ? Icons.volume_up_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 18,
                                      color: _isPlayingMyVoice
                                          ? kColorPrimary
                                          : kColorTextMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPlayingMyVoice
                                          ? 'Playing…'
                                          : 'My Voice',
                                      style: TextStyle(
                                        color: _isPlayingMyVoice
                                            ? kColorPrimary
                                            : kColorTextMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isPlayingTts
                                  ? null
                                  : _playCorrectPronunciation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isPlayingTts
                                      ? kColorAccent.withValues(alpha: 0.15)
                                      : kColorSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isPlayingTts
                                        ? kColorAccent.withValues(alpha: 0.4)
                                        : kColorBorder.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlayingTts
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_up_outlined,
                                      size: 18,
                                      color: _isPlayingTts
                                          ? kColorAccent
                                          : kColorTextMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPlayingTts
                                          ? 'Playing…'
                                          : 'Correct Pronunciation',
                                      style: TextStyle(
                                        color: _isPlayingTts
                                            ? kColorAccent
                                            : kColorTextMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
