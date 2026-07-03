import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'ui_strings.dart';

class BeginnerScreen extends StatefulWidget {
  const BeginnerScreen({super.key});

  @override
  State<BeginnerScreen> createState() => _BeginnerScreenState();
}

class _BeginnerScreenState extends State<BeginnerScreen> {
  final FlutterTts _tts = FlutterTts();
  final Set<String> _loadingWords = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final textDirection = textDirectionForCode(state.nativeLanguage);
        return Directionality(
          textDirection: textDirection,
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorPrimary.withValues(alpha: 0.1),
                    backgroundBlendMode: BlendMode.screen,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 100.0, 24.0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildModeHeader(state),
                          const SizedBox(height: 20),
                          _buildVocabProgress(state),
                          const SizedBox(height: 24),
                          if (state.beginnerLoading)
                            _buildShimmerLoading()
                          else if (!state.beginnerHasSentence)
                            _buildWelcomeSection(state)
                          else ...[
                            _buildSentenceCard(state),
                            const SizedBox(height: 24),
                            _buildNewWordsSection(state),
                            const SizedBox(height: 24),
                            _buildActions(state),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (state.beginnerVocabulary.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildVocabHeader(state),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) =>
                              _buildVocabItem(i, state.beginnerVocabulary),
                          childCount: state.beginnerVocabulary.length,
                        ),
                      ),
                    ),
                    if (state.beginnerVocabulary.length > 20)
                      SliverPadding(
                        padding:
                            const EdgeInsets.only(left: 24, right: 24, top: 8),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              '+ ${state.beginnerVocabulary.length - 20} more words',
                              style: TextStyle(
                                color: kColorTextMuted.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 100),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeHeader(AppStateModel state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kColorSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'beginner'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kColorText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    tr(context, 'learnWordsThroughContext'),
                    style: TextStyle(
                      color: kColorTextMuted.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabProgress(AppStateModel state) {
    final count = state.beginnerVocabulary.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: kPrimaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'wordsDiscovered'),
                  style: TextStyle(
                    color: kColorText.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (count / 50).clamp(0.0, 1.0),
                    backgroundColor: kColorBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      count >= 50 ? const Color(0xFF2ECC71) : kColorPrimary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${count ~/ 5 * 5}+',
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.6),
              fontSize: 20,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: kColorSurface,
      highlightColor: kColorBorder,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: kColorSurface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: kColorSurface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AppStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: kCardGradient,
            border: Border.all(color: kColorBorder),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr(context, 'startYourJourney'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(context, 'learnFirstWordDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.8),
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _generateNewSentence(state),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kColorPrimary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          tr(context, 'learnMyFirstWord'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentenceCard(AppStateModel state) {
    final words = state.beginnerSentence.split(' ');
    final knownWords = state.beginnerVocabulary
        .map((e) => (e['word'] ?? '').trim().toLowerCase())
        .toSet();
    final newWords = state.beginnerCurrentNewWords.map((e) => e.word).toSet();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: kCardGradient,
        border: Border.all(color: kColorBorder),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target word tag
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: kColorPrimary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Tap words to learn',
                      style: TextStyle(
                        color: kColorPrimary.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Interactive sentence
          Wrap(
            spacing: 6,
            runSpacing: 6,
            textDirection: TextDirection.ltr,
            children: words.map((word) {
              final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
              final isKnown = knownWords.contains(cleanWord.toLowerCase()) ||
                  knownWords.contains(word.toLowerCase()) ||
                  cleanWord.isEmpty;
              final isNew = newWords.contains(cleanWord) ||
                  newWords.contains(word.toLowerCase());
              final isTarget = cleanWord.toLowerCase() ==
                  state.beginnerTargetWord.toLowerCase();

              Color bgColor;
              Color textColor;
              if (isTarget) {
                bgColor = kColorPrimary.withValues(alpha: 0.2);
                textColor = kColorPrimary;
              } else if (isNew) {
                bgColor = const Color(0xFFFF8E53).withValues(alpha: 0.15);
                textColor = const Color(0xFFFF8E53);
              } else if (isKnown) {
                bgColor = const Color(0xFF2ECC71).withValues(alpha: 0.1);
                textColor = const Color(0xFF2ECC71);
              } else {
                bgColor = kColorAccent.withValues(alpha: 0.08);
                textColor = kColorAccent;
              }

              final isLoading = _loadingWords.contains(cleanWord);
              return GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        if (isKnown) {
                          _onWordTap(state, cleanWord);
                        } else {
                          setState(() => _loadingWords.add(cleanWord));
                          _onWordTap(state, cleanWord).then((_) {
                            if (mounted)
                              setState(() => _loadingWords.remove(cleanWord));
                          });
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: textColor.withValues(alpha: isLoading ? 0.6 : 0.3),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        )
                      : Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            word,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: isTarget
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _legendDot(kColorPrimary, 'Target'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFFF8E53), 'New'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF2ECC71), 'Known'),
              const SizedBox(width: 16),
              _legendDot(kColorAccent, 'Tap to learn'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: kColorTextMuted.withValues(alpha: 0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildNewWordsSection(AppStateModel state) {
    final newWords = state.beginnerCurrentNewWords;
    if (newWords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8E53).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8E53).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFF8E53), size: 16),
              const SizedBox(width: 8),
              Text(
                'New words in this sentence',
                style: TextStyle(
                  color: const Color(0xFFFF8E53).withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...newWords.map((nw) {
            final isDiscovered = state.beginnerVocabulary.any((e) =>
                (e['word'] ?? '').trim().toLowerCase() ==
                nw.word.trim().toLowerCase());
            if (isDiscovered) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8E53).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      nw.word,
                      style: const TextStyle(
                        color: Color(0xFFFF8E53),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nw.meaning,
                      style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _discoverWord(state, nw.word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Color(0xFF2ECC71), size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Color(0xFF2ECC71),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(AppStateModel state) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _generateNewSentence(state),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      tr(context, 'nextSentence'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVocabHeader(AppStateModel state) {
    final vocab = state.beginnerVocabulary;
    if (vocab.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: kColorTextMuted, size: 16),
          const SizedBox(width: 8),
          Text(
            '${tr(context, 'myVocabulary')} (${vocab.length})',
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabItem(int index, List<Map<String, String>> vocab) {
    final entry = vocab[index];
    final word = entry['word'] ?? '';
    final isFirst = index == 0;
    final isLast = index == vocab.length - 1;
    return Container(
      decoration: BoxDecoration(
        color: kColorSurface.withValues(alpha: 0.5),
        borderRadius: isFirst && isLast
            ? BorderRadius.circular(16)
            : isFirst
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )
                : isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : null,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: kColorBorder.withValues(alpha: 0.3)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2ECC71),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            word,
            style: const TextStyle(
              color: kColorText,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry['meaning'] ?? '',
              style: TextStyle(
                color: kColorTextMuted.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _speakVocabWord(word),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kColorPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: kColorPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakVocabWord(String word) async {
    final lang = context.read<AppStateModel>().targetLanguage;
    await _tts.setLanguage(ttsLocaleFor(lang));
    await _tts.speak(word);
  }

  Future<void> _generateNewSentence(AppStateModel state) async {
    setState(() {
      _loadingWords.clear();
    });
    final error = await state.generateBeginnerSentence();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: kColorError,
        ),
      );
    }
  }

  Future<void> _onWordTap(AppStateModel state, String word) async {
    if (word.isEmpty) return;

    // Check if already known (ignore case, spacing, and meaning)
    final clean = word.trim().toLowerCase();
    final isKnown = state.beginnerVocabulary
        .any((e) => (e['word'] ?? '').trim().toLowerCase() == clean);
    if (isKnown) {
      final meaning = state.beginnerVocabulary
          .firstWhere((e) => e['word'] == word)['meaning'];
      if (meaning != null && meaning.isNotEmpty) {
        _showMeaningSheet(word, meaning, null);
      }
      return;
    }

    // Discover the word
    final error = await state.discoverBeginnerWord(word);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: kColorError,
        ),
      );
      return;
    }

    // Show the meaning
    final updatedVocab = state.beginnerVocabulary;
    final match = updatedVocab.firstWhere(
      (e) => e['word'] == word,
      orElse: () => {'word': word, 'meaning': ''},
    );
    _showMeaningSheet(word, match['meaning'] ?? '', null);
  }

  Future<void> _discoverWord(AppStateModel state, String word) async {
    if (word.isEmpty) return;
    final error = await state.discoverBeginnerWord(word);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: kColorError,
        ),
      );
    }
  }

  void _showMeaningSheet(String word, String meaning, String? example) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WordMeaningSheet(
        word: word,
        meaning: meaning,
        example: example,
      ),
    );
  }
}

// ─── Word Meaning Bottom Sheet ─────────────────────────────────────────────────

class _WordMeaningSheet extends StatelessWidget {
  final String word;
  final String meaning;
  final String? example;

  const _WordMeaningSheet({
    required this.word,
    required this.meaning,
    this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kColorBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: kAccentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  tr(context, 'newWord'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kColorText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: kColorTextMuted, size: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kColorPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kColorPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Meaning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kColorSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kColorBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meaning',
                        style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meaning.isNotEmpty
                            ? meaning
                            : 'Added to your vocabulary!',
                        style: const TextStyle(
                          color: kColorText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (example != null && example!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kColorAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kColorAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example',
                          style: TextStyle(
                            color: kColorTextMuted.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          example!,
                          style: TextStyle(
                            color: kColorAccent.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2ECC71), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Added to your vocabulary',
                        style: TextStyle(
                          color: Color(0xFF2ECC71),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
