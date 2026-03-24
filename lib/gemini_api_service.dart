// lib/gemini_api_service.dart
// Stateless service that wraps all Gemini API interactions.
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

// ─── Response model ───────────────────────────────────────────────────────────

class AnswerAnalysis {
  final String feedback;
  final List<String> examples;

  const AnswerAnalysis({required this.feedback, required this.examples});

  factory AnswerAnalysis.empty() =>
      const AnswerAnalysis(feedback: '', examples: ['', '', '']);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class GeminiApiService {
  // gemini-2.0-flash-lite: 30 RPM free tier (vs 15 for flash).
  // Best choice for rapid dev usage — still very capable.
  static const String _modelName = 'gemini-2.5-flash';
  static const Duration _timeout = Duration(seconds: 30);

  // Max retry attempts and delays (seconds) for rate-limit errors.
  static const int _maxRetries = 3;
  static const List<int> _retryDelays = [2, 4, 8]; // exponential back-off

  // ── helpers ──

  GenerativeModel _buildModel(String apiKey) =>
      GenerativeModel(model: _modelName, apiKey: apiKey);

  /// Runs [call], retrying automatically on rate-limit errors.
  /// Other errors are rethrown immediately.
  Future<T> _withRetry<T>(Future<T> Function() call) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await call();
      } on GeminiServiceException catch (e) {
        final isLast = attempt == _maxRetries;
        if (e.type == GeminiErrorType.quotaExceeded && !isLast) {
          // Wait, then retry silently.
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
    // Exhausted all retries.
    throw const GeminiServiceException(
      GeminiErrorType.quotaExceeded,
      'Rate limit — still busy after 3 retries. Wait 30 s then try again.',
    );
  }

  /// Maps SDK exceptions to typed [GeminiServiceException].
  /// Uses precise SDK status codes to avoid mis-classification.
  GeminiServiceException _classify(Object e) {
    final raw = e.toString();
    final msg = raw.toLowerCase();

    // ── Authentication / bad key ──────────────────────────────────────────
    // gRPC UNAUTHENTICATED (16) or HTTP 401/403
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

    // ── Quota / rate limit ────────────────────────────────────────────────
    // gRPC RESOURCE_EXHAUSTED (8) or HTTP 429
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

    // ── Network / timeout ─────────────────────────────────────────────────
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

    // ── Fallback: show the raw SDK message so it is always diagnosable ────
    return GeminiServiceException(
      GeminiErrorType.unknown,
      raw.length > 300 ? '${raw.substring(0, 300)}…' : raw,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sends a minimal 1-token prompt to verify the [apiKey] works.
  /// Returns `true` on success, throws [GeminiServiceException] on failure.
  Future<bool> testApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw const GeminiServiceException(
        GeminiErrorType.invalidApiKey,
        'API key cannot be empty.',
      );
    }
    return _withRetry(() async {
      final model = _buildModel(apiKey.trim());
      // Minimal prompt — 1 token — to minimise quota usage during test.
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

  /// Generates a practice question for the given [topic] and languages.
  Future<String> generateQuestion({
    required String apiKey,
    required String nativeLanguage,
    required String targetLanguage,
    required String topic,
  }) async {
    return _withRetry(() async {
      final prompt = buildQuestionPrompt(
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
          'The AI returned an empty question. Please try again.',
        );
      }
      return text;
    });
  }

  /// Submits the user's [answer] and returns an [AnswerAnalysis].
  Future<AnswerAnalysis> analyzeAnswer({
    required String apiKey,
    required String nativeLanguage,
    required String targetLanguage,
    required String topic,
    required String question,
    required String answer,
  }) async {
    return _withRetry(() async {
      final prompt = buildFeedbackPrompt(
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        topic: topic,
        question: question,
        userAnswer: answer,
      );
      final model = _buildModel(apiKey.trim());
      final response =
          await model.generateContent([Content.text(prompt)]).timeout(_timeout);
      final rawText = response.text?.trim() ?? '';
      return _parseAnalysis(rawText);
    });
  }

  // ── JSON parsing ──────────────────────────────────────────────────────────

  AnswerAnalysis _parseAnalysis(String rawText) {
    try {
      // Strip optional markdown code fences: ```json ... ```
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

      // Pad to exactly 3 examples.
      while (examples.length < 3) {
        examples.add('');
      }

      return AnswerAnalysis(
        feedback: feedback.isEmpty ? 'No feedback received.' : feedback,
        examples: examples.take(3).toList(),
      );
    } catch (_) {
      // Graceful fallback — show raw text as feedback.
      return AnswerAnalysis(
        feedback: rawText.isNotEmpty
            ? rawText
            : 'Could not parse the AI response. Please try again.',
        examples: ['', '', ''],
      );
    }
  }
  Future<String> generateNextQuestion({
  required String apiKey,
  required String nativeLanguage,
  required String targetLanguage,
  required String topic,
  required String previousQuestion,
  required String userAnswer,
}) async {
  return _withRetry(() async {
    final prompt = '''You are a friendly language tutor teaching $targetLanguage to a $nativeLanguage speaker.

The student was practicing "$topic".
Previous question: "$previousQuestion"
Student's answer: "$userAnswer"

Based on their answer, generate ONE natural follow-up question that:
- Continues the conversation naturally (like a real dialogue)
- Is directly connected to what they just said
- Encourages them to say more in $targetLanguage
- Is slightly more challenging than the previous question

Reply with ONLY the follow-up question — no explanation, no numbering.''';

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
}
