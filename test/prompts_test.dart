import 'package:flutter_test/flutter_test.dart';
import 'package:salearn/data/prompts.dart';

void main() {
  group('buildQuestionPrompt', () {
    test('includes target language and topic', () {
      final prompt = buildQuestionPrompt(
        targetLanguage: 'French',
        nativeLanguage: 'English',
        topic: 'Travel',
        level: 'B1',
      );
      expect(prompt, contains('French'));
      expect(prompt, contains('Travel'));
      expect(prompt, contains('B1'));
      expect(prompt, contains('Level Rules'));
    });

    test('uses A1 rules for A1 level', () {
      final prompt = buildQuestionPrompt(
        targetLanguage: 'Spanish',
        nativeLanguage: 'English',
        topic: 'Daily Conversations',
        level: 'A1',
      );
      expect(prompt, contains('(A1 — Beginner)'));
      expect(prompt, contains('Maximum 8 words'));
    });
  });

  group('buildFeedbackPrompt', () {
    test('includes question and answer context', () {
      final prompt = buildFeedbackPrompt(
        targetLanguage: 'German',
        nativeLanguage: 'English',
        topic: 'Food',
        question: 'Was isst du gern?',
        userAnswer: 'Ich esse Pizza gern.',
        level: 'A2',
      );
      expect(prompt, contains('Was isst du gern?'));
      expect(prompt, contains('Ich esse Pizza gern.'));
      expect(prompt, contains('feedback'));
      expect(prompt, contains('examples'));
    });
  });

  group('buildNextQuestionPrompt', () {
    test('includes conversation context', () {
      final prompt = buildNextQuestionPrompt(
        targetLanguage: 'French',
        nativeLanguage: 'English',
        topic: 'Technology',
        previousQuestion: 'Utilisez-vous l\'IA ?',
        userAnswer: 'Oui, tous les jours.',
        level: 'B1',
      );
      expect(prompt, contains('Utilisez-vous'));
      expect(prompt, contains('Oui'));
      expect(prompt, contains('follow-up question'));
    });
  });

  group('buildTranslationPrompt', () {
    test('includes text to translate', () {
      final prompt = buildTranslationPrompt(
        text: 'Hello, how are you?',
        fromLanguage: 'English',
        toLanguage: 'French',
      );
      expect(prompt, contains('Hello, how are you?'));
      expect(prompt, contains('English'));
      expect(prompt, contains('French'));
    });
  });

  group('buildTestQuestionPrompt', () {
    test('first question starts at A2 difficulty', () {
      final prompt = buildTestQuestionPrompt(
        targetLanguage: 'Spanish',
        nativeLanguage: 'English',
        questionNumber: 1,
        totalQuestions: 5,
        previousQA: [],
      );
      expect(prompt, contains('first question'));
      expect(prompt, contains('A2'));
    });

    test('subsequent questions include Q&A history', () {
      final prompt = buildTestQuestionPrompt(
        targetLanguage: 'French',
        nativeLanguage: 'English',
        questionNumber: 2,
        totalQuestions: 5,
        previousQA: [
          {
            'question': 'Test?',
            'selected': 'A',
            'correct_answer': 'A',
            'level': 'A2',
          },
        ],
      );
      expect(prompt, contains('CORRECT'));
      expect(prompt, contains('Test?'));
    });
  });

  group('buildProficiencyEvaluationPrompt', () {
    test('includes Q&A history', () {
      final prompt = buildProficiencyEvaluationPrompt(
        targetLanguage: 'German',
        nativeLanguage: 'English',
        qaHistory: [
          {
            'question': 'Wie geht es dir?',
            'selected': 'Gut',
            'correct_answer': 'Gut',
            'level': 'A1',
          },
        ],
      );
      expect(prompt, contains('Wie geht es dir?'));
      expect(prompt, contains('Gut'));
      expect(prompt, contains('CORRECT'));
      expect(prompt, contains('CEFR'));
    });
  });
}
