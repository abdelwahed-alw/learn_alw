// lib/constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const String kPrefApiKey        = 'api_key';
const String kPrefNativeLang    = 'native_language';
const String kPrefTargetLang    = 'target_language';
const String kPrefTopic         = 'selected_topic';

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
    orElse: () => {'label': code, 'code': code},
  )['label']!;
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

// ─── Prompt templates ─────────────────────────────────────────────────────────
String buildQuestionPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required String topic,
}) {
  return '''You are a language tutor expert in $targetLanguage and $nativeLanguage.
Generate ONE short, engaging practice question about "$topic" for a student learning $targetLanguage.
The question should require a written answer in $targetLanguage (2–5 sentences).
Reply with ONLY the question text — no explanation, no numbering, no quotation marks.''';
}

String buildFeedbackPrompt({
  required String targetLanguage,
  required String nativeLanguage,
  required String topic,
  required String question,
  required String userAnswer,
}) {
  return '''You are an expert language tutor with expertise in $targetLanguage and $nativeLanguage. The user is practicing "$topic". The user was asked: "$question". The user responded in $targetLanguage with: "$userAnswer".

Analyze the user's response. Return the response ONLY in valid JSON format with this exact structure:
{
  "feedback": "Explain grammatical, spelling, and vocabulary mistakes here. Speak directly to the user in $nativeLanguage using a friendly, peer-to-peer tone. If the answer is perfect, congratulate them warmly.",
  "examples": [
    "First complete, natural alternative in $targetLanguage",
    "Second complete alternative in $targetLanguage",
    "Third complete alternative in $targetLanguage"
  ]
}

Return ONLY valid JSON. Do not include any text before or after the JSON block.''';
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