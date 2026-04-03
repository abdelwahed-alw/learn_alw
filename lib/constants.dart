// lib/constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const String kPrefApiKey        = 'api_key';
const String kPrefNativeLang    = 'native_language';
const String kPrefTargetLang    = 'target_language';
const String kPrefTopic         = 'selected_topic';
const String kPrefLevel         = 'proficiency_level';
const String kPrefOnboarding    = 'onboarding_done';

// ─── YouTube tutorial ─────────────────────────────────────────────────────────
const String kYoutubeTutorialUrl =
    'https://www.youtube.com/watch?v=PLACEHOLDER_TUTORIAL_ID';

// ─── Supported languages ──────────────────────────────────────────────────────
const List<Map<String, String>> kSupportedLanguages = [
  {'label': 'Arabic',     'code': 'ar'},
  {'label': 'English',    'code': 'en'},
  {'label': 'French',     'code': 'fr'},
  {'label': 'Spanish',    'code': 'es'},
  {'label': 'German',     'code': 'de'},
  {'label': 'Turkish',    'code': 'tr'},
  {'label': 'Italian',    'code': 'it'},
  {'label': 'Portuguese', 'code': 'pt'},
  {'label': 'Chinese',    'code': 'zh'},
  {'label': 'Japanese',   'code': 'ja'},
];

String languageLabelFromCode(String code) {
  return kSupportedLanguages.firstWhere(
    (l) => l['code'] == code,
    orElse: () => <String, String>{'label': code, 'code': code},
  )['label']!;
}

// ─── CEFR Proficiency Levels ──────────────────────────────────────────────────
const List<Map<String, String>> kCefrLevels = [
  {
    'code': 'A1',
    'label': 'Beginner',
    'emoji': '🌱',
    'description': 'Basic phrases and simple interactions',
  },
  {
    'code': 'A2',
    'label': 'Elementary',
    'emoji': '🌿',
    'description': 'Routine tasks and familiar topics',
  },
  {
    'code': 'B1',
    'label': 'Intermediate',
    'emoji': '🌳',
    'description': 'Main points and everyday situations',
  },
  {
    'code': 'B2',
    'label': 'Upper Intermediate',
    'emoji': '🌲',
    'description': 'Complex texts and abstract topics',
  },
  {
    'code': 'C1',
    'label': 'Advanced',
    'emoji': '⭐',
    'description': 'Fluent expression and implicit meaning',
  },
  {
    'code': 'C2',
    'label': 'Mastery',
    'emoji': '👑',
    'description': 'Near-native precision and nuance',
  },
];

String levelLabel(String code) {
  return kCefrLevels.firstWhere(
    (l) => l['code'] == code,
    orElse: () => <String, String>{'label': code},
  )['label']!;
}

String levelEmoji(String code) {
  return kCefrLevels.firstWhere(
    (l) => l['code'] == code,
    orElse: () => <String, String>{'emoji': '📚'},
  )['emoji']!;
}

// ─── Topics ───────────────────────────────────────────────────────────────────
const List<String> kTopics = [
  'Daily Conversations',
  'Movies & TV Shows',
  'Philosophy',
  'Vocabulary Drill',
  'Grammar Practice',
  'Science & Nature',
  'Travel',
  'Technology',
  'Business & Finance',
  'History & Culture',
  'Sports',
  'Food & Cooking',
];

// Topic → Icon mapping for drawer
const Map<String, IconData> kTopicIcons = {
  'Daily Conversations': Icons.chat_bubble_outline_rounded,
  'Movies & TV Shows': Icons.movie_outlined,
  'Philosophy': Icons.psychology_outlined,
  'Vocabulary Drill': Icons.spellcheck_rounded,
  'Grammar Practice': Icons.edit_note_rounded,
  'Science & Nature': Icons.biotech_outlined,
  'Travel': Icons.flight_takeoff_rounded,
  'Technology': Icons.devices_rounded,
  'Business & Finance': Icons.trending_up_rounded,
  'History & Culture': Icons.account_balance_outlined,
  'Sports': Icons.sports_soccer_rounded,
  'Food & Cooking': Icons.restaurant_rounded,
};

// ─── Color Palette — Navy × Coral ────────────────────────────────────────────

// Backgrounds (layered deep navy)
const Color kColorBackground  = Color(0xFF0A192F); // Page bg
const Color kColorSurface     = Color(0xFF112240); // Cards, drawer
const Color kColorCard        = Color(0xFF172A46); // Elevated cards
const Color kColorBorder      = Color(0xFF1E3A5F); // Subtle borders

// Accent Colors
const Color kColorPrimary     = Color(0xFFFF6B6B); // Coral red — buttons, highlights
const Color kColorAccent      = Color(0xFFC7D5E8); // Steel blue — secondary accents
const Color kColorSecondary   = Color(0xFFFF8E53); // Warm orange — gradient partner
const Color kColorError       = Color(0xFFFF4757); // Error red

// Typography
const Color kColorText        = Color(0xFFE8EFF7); // Primary text
const Color kColorTextMuted   = Color(0xFF5577AA); // Muted / placeholder

// ─── Gradients ────────────────────────────────────────────────────────────────

// Coral → warm orange (buttons, CTAs)
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Steel blue → navy (accent areas)
const LinearGradient kAccentGradient = LinearGradient(
  colors: [Color(0xFFC7D5E8), Color(0xFF6B8CAE)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Card inner gradient (subtle depth)
const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFF172A46), Color(0xFF112240)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// Drawer header gradient
const LinearGradient kDrawerGradient = LinearGradient(
  colors: [Color(0xFF1E3A5F), Color(0xFF0A192F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Typography ───────────────────────────────────────────────────────────────
TextTheme buildPremiumTextTheme() {
  return GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
    displayLarge: GoogleFonts.outfit(
        color: kColorText, fontWeight: FontWeight.bold, letterSpacing: -1),
    titleLarge: GoogleFonts.outfit(
        color: kColorText, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    bodyLarge: GoogleFonts.outfit(
        color: kColorText, fontSize: 16, height: 1.6),
    bodyMedium: GoogleFonts.outfit(
        color: kColorText, fontSize: 14, height: 1.5),
    labelLarge: GoogleFonts.outfit(
        color: kColorText, fontWeight: FontWeight.bold, letterSpacing: 0.5),
  );
}

// ─── Level-Aware System Prompt Fragments ──────────────────────────────────────

String _levelRules(String level) {
  switch (level) {
    case 'A1':
      return '''## Level Rules (A1 — Beginner)
- Vocabulary: Use only the 500 most common words. No idioms, no slang.
- Sentences: Maximum 8 words. Simple SVO structure. Present tense only.
- Feedback tone: Very encouraging, use emojis. Celebrate every attempt.
- Question complexity: Yes/no questions, fill-in-the-blank, or "What is this?"
- Expected answer length: 1–2 short sentences.''';
    case 'A2':
      return '''## Level Rules (A2 — Elementary)
- Vocabulary: Common everyday words (~1000 word range). Simple connectors (and, but, because).
- Sentences: Up to 12 words. Present and past tense. Simple compound sentences.
- Feedback tone: Encouraging with gentle corrections. Explain grammar simply.
- Question complexity: Simple "how", "why", "describe" questions about daily life.
- Expected answer length: 2–3 sentences.''';
    case 'B1':
      return '''## Level Rules (B1 — Intermediate)
- Vocabulary: Intermediate range with topic-specific words. Some phrasal verbs.
- Sentences: Complex sentences with subordinate clauses. Multiple tenses allowed.
- Feedback tone: Balanced — acknowledge strengths, point out precise errors with explanations.
- Question complexity: Opinion questions, comparisons, personal experiences.
- Expected answer length: 3–4 sentences.''';
    case 'B2':
      return '''## Level Rules (B2 — Upper Intermediate)
- Vocabulary: Wide range including abstract concepts, collocations, and some idioms.
- Sentences: Complex nested clauses, passive voice, conditionals, subjunctive.
- Feedback tone: Critical and detailed. Point out nuance, register, and style issues.
- Question complexity: Argue a position, analyze scenarios, discuss hypotheticals.
- Expected answer length: 4–6 sentences.''';
    case 'C1':
      return '''## Level Rules (C1 — Advanced)
- Vocabulary: Sophisticated vocabulary, idiomatic expressions, field-specific terminology.
- Sentences: All structures including complex subordination, cleft sentences, inversion.
- Feedback tone: Nuanced critique focusing on precision, register, and stylistic elegance.
- Question complexity: Abstract reasoning, implicit meaning, cultural nuance.
- Expected answer length: 5–8 sentences.''';
    case 'C2':
      return '''## Level Rules (C2 — Mastery)
- Vocabulary: Full native-level range, rare words, literary expressions, subtle connotations.
- Sentences: Total freedom — evaluate as you would a native speaker's writing.
- Feedback tone: Peer-level critique. Focus on elegance, rhetorical devices, and precision.
- Question complexity: Philosophical, literary, or deeply analytical topics.
- Expected answer length: 6–10 sentences.''';
    default:
      return _levelRules('B1');
  }
}

// ─── Prompt templates ─────────────────────────────────────────────────────────

String buildQuestionPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required String topic,
  required String level,
}) {
  return '''You are an expert $targetLanguage language tutor for a $nativeLanguage speaker.

${_levelRules(level)}

## Task
Generate ONE practice question about "$topic" for a $level student learning $targetLanguage.
The question must follow the level rules above strictly.

Reply with ONLY the question text — no explanation, no numbering, no quotation marks.''';
}

String buildFeedbackPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required String topic,
  required String question,
  required String userAnswer,
  required String level,
}) {
  return '''You are an expert $targetLanguage language tutor for a $nativeLanguage speaker.

${_levelRules(level)}

## Context
- Topic: "$topic"
- Question asked: "$question"
- Student's answer in $targetLanguage: "$userAnswer"

## Task
Analyze the student's response following the level rules above. Return ONLY valid JSON:
{
  "feedback": "Your analysis in $nativeLanguage. Follow the feedback tone rules for $level.",
  "examples": [
    "First better alternative in $targetLanguage (matching $level complexity)",
    "Second alternative in $targetLanguage",
    "Third alternative in $targetLanguage"
  ]
}

Return ONLY valid JSON. No text before or after.''';
}

String buildNextQuestionPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required String topic,
  required String previousQuestion,
  required String userAnswer,
  required String level,
}) {
  return '''You are a friendly $targetLanguage tutor for a $nativeLanguage speaker.

${_levelRules(level)}

## Context
The student (level $level) was practicing "$topic".
Previous question: "$previousQuestion"
Student's answer: "$userAnswer"

## Task
Generate ONE natural follow-up question that:
- Continues the conversation naturally
- Follows the level rules above strictly
- Is slightly more challenging than the previous question (but stays within $level)

Reply with ONLY the follow-up question — no explanation, no numbering.''';
}

String buildTranslationPrompt({
  required String text,
  required String fromLanguage,
  required String toLanguage,
}) {
  return '''Translate the following text from $fromLanguage to $toLanguage.
Provide a clear, natural translation. If the text contains vocabulary that may be new to a learner, briefly explain key words.

Text to translate:
"$text"

Reply with ONLY the translation and any brief vocabulary notes. Do not add any other commentary.''';
}

String buildTestQuestionPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required int questionNumber,
  required List<Map<String, String>> previousQA,
}) {
  final qaHistory = previousQA.map((qa) =>
    'Q: "${qa['question']}"\nA: "${qa['answer']}"'
  ).join('\n\n');

  final contextBlock = previousQA.isEmpty
    ? 'This is the first question. Start at a basic level.'
    : '''Previous questions and answers:
$qaHistory

Based on the student's performance, adjust difficulty accordingly.''';

  return '''You are an expert language proficiency examiner for $targetLanguage.
The student speaks $nativeLanguage.

This is question $questionNumber of 5 in a proficiency assessment.

$contextBlock

## Rules
- Question 1: Start at A1–A2 level (very simple)
- Questions 2–3: Adapt based on answers (increase difficulty if correct, decrease if struggling)
- Questions 4–5: Push toward the student's ceiling
- Questions should test: vocabulary, grammar, comprehension, and expression
- Each question should be in $targetLanguage or ask for a response in $targetLanguage

Reply with ONLY the question text — no explanation, no numbering.''';
}

String buildProficiencyEvaluationPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required List<Map<String, String>> qaHistory,
}) {
  final formatted = qaHistory.asMap().entries.map((e) =>
    'Q${e.key + 1}: "${e.value['question']}"\nA${e.key + 1}: "${e.value['answer']}"'
  ).join('\n\n');

  return '''You are an expert CEFR language proficiency evaluator for $targetLanguage.
The student speaks $nativeLanguage natively.

## Assessment Results (5 questions)
$formatted

## Task
Analyze all 5 answers and determine the student's CEFR proficiency level.
Consider: vocabulary range, grammatical accuracy, sentence complexity, and communicative competence.

Return ONLY valid JSON:
{
  "level": "B1",
  "reasoning": "Brief 2-3 sentence explanation of why this level was assigned"
}

The level MUST be one of: A1, A2, B1, B2, C1, C2.
Return ONLY valid JSON.''';
}

// ─── RTL helper ───────────────────────────────────────────────────────────────
const Set<String> kRtlLanguageCodes = {'ar', 'he', 'ur', 'fa'};

TextDirection textDirectionForCode(String langCode) {
  return kRtlLanguageCodes.contains(langCode)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

// ─── Animation Curves ───────────────────────────────────────────────────────────

// Premium natural feel curve (0.4, 0, 0.2, 1)
const Curve kPremiumCurve = Cubic(0.4, 0.0, 0.2, 1.0);

// Bounce curve for drawer
const Curve kBounceCurve = Curves.elasticOut;

// Fast-out curve for quick interactions
const Curve kQuickCurve = Curves.easeOutCubic;

// Spring curve for bouncy/organic feel
const Curve kSpringCurve = Curves.elasticOut;