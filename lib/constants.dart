// lib/constants.dart
// App-wide constants for Learn-Alw – Premium UI Redesign.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const String kPrefApiKey = 'api_key';
const String kPrefNativeLang = 'native_language';
const String kPrefTargetLang = 'target_language';
const String kPrefTopic = 'selected_topic';

// ─── YouTube tutorial placeholder ─────────────────────────────────────────────
const String kYoutubeTutorialUrl =
    'https://www.youtube.com/watch?v=PLACEHOLDER_TUTORIAL_ID';

// ─── Supported languages ──────────────────────────────────────────────────────
const List<Map<String, String>> kSupportedLanguages = [
  {'label': 'Arabic', 'code': 'ar'},
  {'label': 'English', 'code': 'en'},
  {'label': 'French', 'code': 'fr'},
  {'label': 'Spanish', 'code': 'es'},
  {'label': 'German', 'code': 'de'},
  {'label': 'Turkish', 'code': 'tr'},
  {'label': 'Italian', 'code': 'it'},
  {'label': 'Portuguese', 'code': 'pt'},
  {'label': 'Chinese', 'code': 'zh'},
  {'label': 'Japanese', 'code': 'ja'},
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

// ─── Premium Color palette ────────────────────────────────────────────────────
// Rich dark space background
const Color kColorBackground = Color(0xFF090B10);
// Elevated surfaces (cards, sidebars)
const Color kColorSurface = Color(0xFF0F141E);
// Glassmorphism base
const Color kColorCard = Color(0xFF161C27);
const Color kColorBorder = Color(0xFF2B3648);

// Neon Accents
const Color kColorPrimary = Color(0xFF8B5CF6); // Vibrant Purple
const Color kColorAccent = Color(0xFF06B6D4); // Cyan/Teal
const Color kColorSecondary = Color(0xFFF43F5E); // Rose Pink
const Color kColorError = Color(0xFFEF4444); // Red

// Typography Colors
const Color kColorText = Color(0xFFF8FAFC);
const Color kColorTextMuted = Color(0xFF94A3B8);

// Glowing Gradients
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kAccentGradient = LinearGradient(
  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFF161C27), Color(0xFF0F141E)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ─── Typography (Google Fonts) ────────────────────────────────────────────────
TextTheme buildPremiumTextTheme() {
  return GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
    displayLarge: GoogleFonts.outfit(
        color: kColorText, fontWeight: FontWeight.bold, letterSpacing: -1),
    titleLarge: GoogleFonts.outfit(
        color: kColorText, fontWeight: FontWeight.w600, letterSpacing: -0.5),
    bodyLarge: GoogleFonts.outfit(color: kColorText, fontSize: 16, height: 1.6),
    bodyMedium:
        GoogleFonts.outfit(color: kColorText, fontSize: 14, height: 1.5),
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
