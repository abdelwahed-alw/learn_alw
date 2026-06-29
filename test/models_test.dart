import 'package:flutter_test/flutter_test.dart';
import 'package:salearn/data/models.dart';

void main() {
  group('parseAnalysis', () {
    test('parses valid JSON with feedback and examples', () {
      final result = parseAnalysis('''
{
  "feedback": "Great job! You used correct grammar.",
  "examples": ["Example 1", "Example 2", "Example 3"]
}
''');
      expect(result.feedback, 'Great job! You used correct grammar.');
      expect(result.examples, hasLength(3));
      expect(result.examples[0], 'Example 1');
    });

    test('parses JSON wrapped in markdown code fences', () {
      final result = parseAnalysis('''
\`\`\`json
{
  "feedback": "Good effort!",
  "examples": ["Try saying..."]
}
\`\`\`
''');
      expect(result.feedback, 'Good effort!');
      expect(result.examples, hasLength(1));
    });

    test('filters out empty examples', () {
      final result = parseAnalysis('''
{
  "feedback": "Nice work!",
  "examples": ["Valid", "", "Also valid"]
}
''');
      expect(result.examples, hasLength(2));
      expect(result.examples[0], 'Valid');
      expect(result.examples[1], 'Also valid');
    });

    test('returns raw text as fallback when JSON is invalid', () {
      final result = parseAnalysis('Raw non-JSON text response');
      expect(result.feedback, 'Raw non-JSON text response');
      expect(result.examples, isEmpty);
    });

    test('returns empty state for empty input', () {
      final result = parseAnalysis('');
      expect(result.feedback, 'Could not parse the AI response. Please try again.');
      expect(result.examples, isEmpty);
    });

    test('handles missing feedback field', () {
      final result = parseAnalysis('{"examples": ["A"]}');
      expect(result.feedback, 'No feedback received.');
      expect(result.examples, hasLength(1));
    });

    test('handles null examples', () {
      final result = parseAnalysis('{"feedback": "OK", "examples": null}');
      expect(result.feedback, 'OK');
      expect(result.examples, isEmpty);
    });
  });

  group('parseProficiencyResult', () {
    test('parses valid proficiency result', () {
      final result = parseProficiencyResult('''
{
  "level": "B2",
  "reasoning": "Handled complex questions well."
}
''');
      expect(result.level, 'B2');
      expect(result.reasoning, 'Handled complex questions well.');
    });

    test('parses result with code fences', () {
      final result = parseProficiencyResult('''
\`\`\`json
{"level": "C1", "reasoning": "Excellent vocabulary."}
\`\`\`
''');
      expect(result.level, 'C1');
    });

    test('normalizes level to uppercase', () {
      final result = parseProficiencyResult('{"level": "b1", "reasoning": "Solid intermediate."}');
      expect(result.level, 'B1');
    });

    test('defaults to B1 for invalid level', () {
      final result = parseProficiencyResult('{"level": "Z9", "reasoning": "?"}');
      expect(result.level, 'B1');
    });

    test('returns fallback for empty input', () {
      final result = parseProficiencyResult('');
      expect(result.level, 'B1');
      expect(result.reasoning, contains('Could not determine'));
    });
  });

  group('parseMcqQuestion', () {
    test('parses valid MCQ', () {
      final result = parseMcqQuestion('''
{
  "question": "What is the capital of France?",
  "options": ["London", "Paris", "Berlin", "Madrid"],
  "correct_answer": "Paris",
  "level": "A2"
}
''');
      expect(result.question, 'What is the capital of France?');
      expect(result.options, hasLength(4));
      expect(result.correctAnswer, 'Paris');
      expect(result.level, 'A2');
    });

    test('parses MCQ with code fences', () {
      final result = parseMcqQuestion('''
\`\`\`json
{"question": "Test?", "options": ["A", "B", "C", "D"], "correct_answer": "A", "level": "A1"}
\`\`\`
''');
      expect(result.question, 'Test?');
    });

    test('throws on fewer than 2 options', () {
      expect(
        () => parseMcqQuestion('{"question": "Q?", "options": ["A"], "correct_answer": "A", "level": "A1"}'),
        throwsA(isA<GeminiServiceException>()),
      );
    });

    test('throws on empty question', () {
      expect(
        () => parseMcqQuestion('{"question": "", "options": ["A", "B"], "correct_answer": "A", "level": "A1"}'),
        throwsA(isA<GeminiServiceException>()),
      );
    });
  });
}
