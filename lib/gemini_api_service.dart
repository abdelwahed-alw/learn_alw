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

// ─── Service ──────────────────────────────────────────────────────────────────

class GeminiApiService {
  static const String _modelName = 'gemini-2.5-flash';
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

  /// Generates a proficiency test question (adaptive).
  Future<String> generateTestQuestion({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required int questionNumber,
    required List<Map<String, String>> previousQA,
  }) async {
    return _withRetry(() async {
      final prompt = buildTestQuestionPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        questionNumber: questionNumber,
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
      return text;
    });
  }

  /// Evaluates all Q&A pairs and returns a CEFR level.
  Future<ProficiencyResult> evaluateProficiency({
    required String apiKey,
    required String targetLanguage,
    required String nativeLanguage,
    required List<Map<String, String>> qaHistory,
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

  // ── Parsing ───────────────────────────────────────────────────────────────

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
}
