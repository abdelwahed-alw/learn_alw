// lib/gemini_api_service.dart
// Stateless service wrapping all Gemini API interactions.
// Auto-retries on rate-limit errors with exponential backoff (up to 3 attempts).

import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'constants.dart';

// ─── Error types ──────────────────────────────────────────────────────────────

/// Structured error returned from [GeminiApiService] calls.
class GeminiServiceException implements Exception {
  final GeminiErrorType type;
  final String message;
  const GeminiServiceException(this.type, this.message);

  @override
  String toString() => 'GeminiServiceException($type): $message';
}

enum GeminiErrorType {
  invalidApiKey,
  quotaExceeded,
  networkError,
  parseError,
  unknown,
}

// ─── Response models ──────────────────────────────────────────────────────────

class AnswerAnalysis {
  final String feedback;
  final List<String> examples;

  const AnswerAnalysis({required this.feedback, required this.examples});

  factory AnswerAnalysis.empty() =>
      const AnswerAnalysis(feedback: '', examples: ['', '', '']);
}

class ProficiencyResult {
  final String level;
  final String reasoning;

  const ProficiencyResult({required this.level, required this.reasoning});
}

class McqQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String level;

  const McqQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.level,
  });
}

// ─── IELTS Response Models ─────────────────────────────────────────────────────

class IeltsFillBlankExercise {
  final String passage;
  final String blankWord;
  final List<String> options;
  final String explanation;

  const IeltsFillBlankExercise({
    required this.passage,
    required this.blankWord,
    required this.options,
    required this.explanation,
  });
}

class IeltsWritingEvaluation {
  final String feedback;
  final double bandScore;
  final List<String> corrections;
  final Map<String, String> vocabularySuggestions;

  const IeltsWritingEvaluation({
    required this.feedback,
    required this.bandScore,
    required this.corrections,
    required this.vocabularySuggestions,
  });
}

class IeltsSentenceEvaluation {
  final String feedback;
  final bool isCorrect;
  final String suggestedCompletion;

  const IeltsSentenceEvaluation({
    required this.feedback,
    required this.isCorrect,
    required this.suggestedCompletion,
  });
}

// ─── Beginner Mode Response Models ────────────────────────────────────────────

class BeginnerSentence {
  final String targetWord;
  final String sentence;
  final List<BeginnerNewWord> newWords;

  const BeginnerSentence({
    required this.targetWord,
    required this.sentence,
    required this.newWords,
  });
}

class BeginnerNewWord {
  final String word;
  final String meaning;

  const BeginnerNewWord({required this.word, required this.meaning});
}

class WordMeaning {
  final String word;
  final String meaning;
  final String exampleSentence;

  const WordMeaning({
    required this.word,
    required this.meaning,
    required this.exampleSentence,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class GeminiApiService {
  static const String _modelName = 'gemini-3.1-flash-lite';
  static const Duration _timeout = Duration(seconds: 30);

  static const int _maxRetries = 3;
  static const List<int> _retryDelays = [2, 4, 8];

  // ── helpers ──

  GenerativeModel _buildModel(String apiKey) =>
      GenerativeModel(model: _modelName, apiKey: apiKey);

  Future<T> _withRetry<T>(Future<T> Function() call) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await call();
      } on GeminiServiceException catch (e) {
        final isLast = attempt == _maxRetries;
        if (e.type == GeminiErrorType.quotaExceeded && !isLast) {
          await Future.delayed(Duration(seconds: _retryDelays[attempt]));
          continue;
        }
        rethrow;
      } catch (e) {
        final classified = _classify(e);
        final isLast = attempt == _maxRetries;
        if (classified.type == GeminiErrorType.quotaExceeded && !isLast) {
          await Future.delayed(Duration(seconds: _retryDelays[attempt]));
          continue;
        }
        throw classified;
      }
    }
    throw const GeminiServiceException(
      GeminiErrorType.quotaExceeded,
      'Rate limit — still busy after 3 retries. Wait 30 s then try again.',
    );
  }

  GeminiServiceException _classify(Object e) {
    final raw = e.toString();
    final msg = raw.toLowerCase();

    if (msg.contains('unauthenticated') ||
        msg.contains('api_key_invalid') ||
        msg.contains('api key not valid') ||
        msg.contains('[401]') ||
        msg.contains('status: 401') ||
        msg.contains('[403]') ||
        msg.contains('status: 403') ||
        msg.contains('permission_denied')) {
      return GeminiServiceException(
        GeminiErrorType.invalidApiKey,
        'Invalid API key. Please check your key in the sidebar.',
      );
    }

    if (msg.contains('resource_exhausted') ||
        msg.contains('quota') ||
        msg.contains('[429]') ||
        msg.contains('status: 429') ||
        msg.contains('too many requests') ||
        msg.contains('rate limit')) {
      return GeminiServiceException(
        GeminiErrorType.quotaExceeded,
        'Rate limit hit. Retrying…',
      );
    }

    if (msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network')) {
      return GeminiServiceException(
        GeminiErrorType.networkError,
        'Network error. Please check your internet connection.',
      );
    }

    return GeminiServiceException(
      GeminiErrorType.unknown,
      raw.length > 300 ? '${raw.substring(0, 300)}…' : raw,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Verify API key with a minimal prompt.
  Future<bool> testApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw const GeminiServiceException(
        GeminiErrorType.invalidApiKey,
        'API key cannot be empty.',
      );
    }
    return _withRetry(() async {
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text('Hi')]).timeout(_timeout);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'Empty response from API. Key may be invalid.',
        );
      }
      return true;
    });
  }

  /// Generates a level-appropriate practice question.
  Future<String> generateQuestion({
    required String apiKey,
    required String nativeLanguage,
    required String targetLanguage,
    required String topic,
    required String level,
  }) async {
    return _withRetry(() async {
      final prompt = buildQuestionPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
        level: level,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'The AI returned an empty question. Please try again.',
        );
      }
      return text;
    });
  }

  /// Submits the user's answer and returns level-aware analysis.
  Future<AnswerAnalysis> analyzeAnswer({
    required String apiKey,
    required String nativeLanguage,
    required String targetLanguage,
    required String topic,
    required String question,
    required String answer,
    required String level,
  }) async {
    return _withRetry(() async {
      final prompt = buildFeedbackPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
        question: question,
        userAnswer: answer,
        level: level,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseAnalysis(rawText);
    });
  }

  /// Generates a level-aware contextual follow-up question.
  Future<String> generateNextQuestion({
    required String apiKey,
    required String nativeLanguage,
    required String targetLanguage,
    required String topic,
    required String previousQuestion,
    required String userAnswer,
    required String level,
  }) async {
    return _withRetry(() async {
      final prompt = buildNextQuestionPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
        previousQuestion: previousQuestion,
        userAnswer: userAnswer,
        level: level,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'The AI returned an empty question. Please try again.',
        );
      }
      return text;
    });
  }

  /// Translates text between languages.
  Future<String> translateText({
    required String apiKey,
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    return _withRetry(() async {
      final prompt = buildTranslationPrompt(
        text: text,
        fromLanguage: fromLanguage,
        toLanguage: toLanguage,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final result = response.text?.trim();
      if (result == null || result.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'Translation returned empty. Please try again.',
        );
      }
      return result;
    });
  }

  /// Generates a proficiency test MCQ question (adaptive).
  Future<McqQuestion> generateTestQuestion({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required int questionNumber,
    required int totalQuestions,
    required List<Map<String, dynamic>> previousQA,
  }) async {
    return _withRetry(() async {
      final prompt = buildTestQuestionPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        questionNumber: questionNumber,
        totalQuestions: totalQuestions,
        previousQA: previousQA,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'Test question generation failed. Please try again.',
        );
      }
      return _parseMcqQuestion(text);
    });
  }

  /// Evaluates all Q&A pairs and returns a CEFR level.
  Future<ProficiencyResult> evaluateProficiency({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required List<Map<String, dynamic>> qaHistory,
  }) async {
    return _withRetry(() async {
      final prompt = buildProficiencyEvaluationPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        qaHistory: qaHistory,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseProficiencyResult(rawText);
    });
  }

  // ── IELTS Methods ─────────────────────────────────────────────────────────

  /// Generates an IELTS fill-in-the-blank exercise.
  Future<IeltsFillBlankExercise> generateIeltsFillBlank({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String topic,
  }) async {
    return _withRetry(() async {
      final prompt = buildIeltsFillBlankPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseIeltsFillBlank(rawText);
    });
  }

  /// Generates an IELTS sentence completion stem.
  Future<String> generateIeltsSentenceStart({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String topic,
  }) async {
    return _withRetry(() async {
      final prompt = buildIeltsSentenceCompletionPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'Sentence completion generation failed. Please try again.',
        );
      }
      return text;
    });
  }

  /// Generates an IELTS writing prompt.
  Future<String> generateIeltsWritingPrompt({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String topic,
  }) async {
    return _withRetry(() async {
      final prompt = buildIeltsWritingPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.unknown,
          'Writing prompt generation failed. Please try again.',
        );
      }
      return text;
    });
  }

  /// Evaluates an IELTS writing submission.
  Future<IeltsWritingEvaluation> evaluateIeltsWriting({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String prompt,
    required String userAnswer,
  }) async {
    return _withRetry(() async {
      final evalPrompt = buildIeltsWritingEvaluationPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        prompt: prompt,
        userAnswer: userAnswer,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(evalPrompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseIeltsWritingEvaluation(rawText);
    });
  }

  /// Evaluates an IELTS sentence completion.
  Future<IeltsSentenceEvaluation> evaluateIeltsSentenceCompletion({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String sentenceStart,
    required String userCompletion,
  }) async {
    return _withRetry(() async {
      final prompt = buildIeltsSentenceEvalPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        sentenceStart: sentenceStart,
        userCompletion: userCompletion,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseIeltsSentenceEvaluation(rawText);
    });
  }

  // ── Beginner Mode Methods ──────────────────────────────────────────────────

  /// Generates a beginner-friendly sentence introducing a target word.
  Future<BeginnerSentence> generateBeginnerSentence({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required String targetWord,
    required List<String> knownWords,
  }) async {
    return _withRetry(() async {
      final prompt = buildBeginnerSentencePrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        targetWord: targetWord,
        knownWords: knownWords,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseBeginnerSentence(rawText);
    });
  }

  /// Gets the meaning of a word for a beginner.
  Future<WordMeaning> getWordMeaning({
    required String apiKey,
    required String word,
    required String targetLanguage,
    required String nativeLanguage,
  }) async {
    return _withRetry(() async {
      final prompt = buildWordMeaningPrompt(
        word: word,
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseWordMeaning(rawText);
    });
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  String _cleanJson(String rawText) {
    String cleaned = rawText;
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'```\s*$'), '')
          .trim();
    }
    return cleaned;
  }

  IeltsFillBlankExercise _parseIeltsFillBlank(String rawText) {
    try {
      final cleaned = _cleanJson(rawText);
      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final passage = (json['passage'] as String? ?? '').trim();
      final blankWord = (json['blankWord'] as String? ?? '').trim();
      final rawOptions = json['options'] as List<dynamic>? ?? [];
      final options =
          rawOptions.map((e) => (e as String? ?? '').trim()).toList();
      final explanation = (json['explanation'] as String? ?? '').trim();

      if (passage.isEmpty || blankWord.isEmpty || options.length < 2) {
        throw const GeminiServiceException(
          GeminiErrorType.parseError,
          'Invalid IELTS fill-blank format. Please try again.',
        );
      }

      return IeltsFillBlankExercise(
        passage: passage,
        blankWord: blankWord,
        options: options,
        explanation: explanation,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse IELTS fill-blank exercise. Please try again.',
      );
    }
  }

  IeltsWritingEvaluation _parseIeltsWritingEvaluation(String rawText) {
    try {
      final cleaned = _cleanJson(rawText);
      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final feedback = (json['feedback'] as String? ?? '').trim();
      final bandScore = (json['bandScore'] as num? ?? 0).toDouble();
      final rawCorrections = json['corrections'] as List<dynamic>? ?? [];
      final corrections =
          rawCorrections.map((e) => (e as String? ?? '').trim()).toList();
      final rawVocab = json['vocabularySuggestions'] as Map<String, dynamic>? ?? {};
      final vocabSuggestions = rawVocab.map(
        (k, v) => MapEntry(k, (v as String? ?? '').trim()),
      );

      return IeltsWritingEvaluation(
        feedback: feedback,
        bandScore: bandScore,
        corrections: corrections,
        vocabularySuggestions: vocabSuggestions,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse IELTS writing evaluation. Please try again.',
      );
    }
  }

  IeltsSentenceEvaluation _parseIeltsSentenceEvaluation(String rawText) {
    try {
      final cleaned = _cleanJson(rawText);
      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final feedback = (json['feedback'] as String? ?? '').trim();
      final isCorrect = json['isCorrect'] as bool? ?? false;
      final suggestedCompletion =
          (json['suggestedCompletion'] as String? ?? '').trim();

      return IeltsSentenceEvaluation(
        feedback: feedback,
        isCorrect: isCorrect,
        suggestedCompletion: suggestedCompletion,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse sentence evaluation. Please try again.',
      );
    }
  }

  BeginnerSentence _parseBeginnerSentence(String rawText) {
    try {
      final cleaned = _cleanJson(rawText);
      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final targetWord = (json['targetWord'] as String? ?? '').trim();
      final sentence = (json['sentence'] as String? ?? '').trim();
      final rawNewWords = json['newWords'] as List<dynamic>? ?? [];

      final newWords = rawNewWords.map((e) {
        final map = e as Map<String, dynamic>;
        return BeginnerNewWord(
          word: (map['word'] as String? ?? '').trim(),
          meaning: (map['meaning'] as String? ?? '').trim(),
        );
      }).toList();

      if (targetWord.isEmpty || sentence.isEmpty) {
        throw const GeminiServiceException(
          GeminiErrorType.parseError,
          'Invalid beginner sentence format.',
        );
      }

      return BeginnerSentence(
        targetWord: targetWord,
        sentence: sentence,
        newWords: newWords,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse beginner sentence. Please try again.',
      );
    }
  }

  WordMeaning _parseWordMeaning(String rawText) {
    try {
      final cleaned = _cleanJson(rawText);
      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final word = (json['word'] as String? ?? '').trim();
      final meaning = (json['meaning'] as String? ?? '').trim();
      final exampleSentence =
          (json['exampleSentence'] as String? ?? '').trim();

      return WordMeaning(
        word: word,
        meaning: meaning,
        exampleSentence: exampleSentence,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse word meaning. Please try again.',
      );
    }
  }

  AnswerAnalysis _parseAnalysis(String rawText) {
    try {
      String cleaned = rawText;
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final feedback = (json['feedback'] as String? ?? '').trim();
      final rawExamples = json['examples'];

      List<String> examples = [];
      if (rawExamples is List) {
        examples = rawExamples.map((e) => (e as String? ?? '').trim()).toList();
      }

      while (examples.length < 3) {
        examples.add('');
      }

      return AnswerAnalysis(
        feedback: feedback.isEmpty ? 'No feedback received.' : feedback,
        examples: examples.take(3).toList(),
      );
    } catch (_) {
      return AnswerAnalysis(
        feedback: rawText.isNotEmpty
            ? rawText
            : 'Could not parse the AI response. Please try again.',
        examples: ['', '', ''],
      );
    }
  }

  ProficiencyResult _parseProficiencyResult(String rawText) {
    try {
      String cleaned = rawText;
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final level = (json['level'] as String? ?? 'B1').trim().toUpperCase();
      final reasoning = (json['reasoning'] as String? ?? '').trim();

      // Validate level
      const validLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
      final finalLevel = validLevels.contains(level) ? level : 'B1';

      return ProficiencyResult(level: finalLevel, reasoning: reasoning);
    } catch (_) {
      return const ProficiencyResult(
        level: 'B1',
        reasoning: 'Could not determine level precisely. Defaulting to B1.',
      );
    }
  }

  McqQuestion _parseMcqQuestion(String rawText) {
    try {
      String cleaned = rawText;
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }

      final Map<String, dynamic> json =
          jsonDecode(cleaned) as Map<String, dynamic>;

      final question = (json['question'] as String? ?? '').trim();
      final rawOptions = json['options'] as List<dynamic>? ?? [];
      final options =
          rawOptions.map((e) => (e as String? ?? '').trim()).toList();
      final correctAnswer = (json['correct_answer'] as String? ?? '').trim();
      final level = (json['level'] as String? ?? 'A2').trim().toUpperCase();

      if (question.isEmpty || options.length < 2) {
        throw const GeminiServiceException(
          GeminiErrorType.parseError,
          'Invalid MCQ format. Please try again.',
        );
      }

      return McqQuestion(
        question: question,
        options: options,
        correctAnswer: correctAnswer,
        level: level,
      );
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw const GeminiServiceException(
        GeminiErrorType.parseError,
        'Could not parse MCQ question. Please try again.',
      );
    }
  }
}
