// lib/app_state_model.dart
// Central state management for Salearn using ChangeNotifier (Provider).
// Persists all settings to SharedPreferences and drives the UI reactively.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

// ── Loading state enum ────────────────────────────────────────────────────────
enum LoadingPhase {
  none, // Idle
  testingKey, // Verifying API key
  generatingQ, // Generating a new question
  submitting, // Analyzing the user's answer
}

// ─── AppStateModel ────────────────────────────────────────────────────────────

class AppStateModel extends ChangeNotifier {
  AppStateModel(this._prefs);

  final SharedPreferences _prefs;
  final GeminiApiService _api = GeminiApiService();

  // ── Persisted settings ───────────────────────────────────────────────────
  String _apiKey = '';
  String _nativeLanguage = 'ar'; // Default: Arabic
  String _targetLanguage = 'en'; // Default: English
  String _selectedTopic = kTopics.first;

  // ── Session state ────────────────────────────────────────────────────────
  String _currentQuestion = '';
  String _feedback = '';
  List<String> _examples = ['', '', ''];
  LoadingPhase _loadingPhase = LoadingPhase.none;
  String _errorMessage = '';

  // ─── Getters ───────────────────────────────────────────────────────────────
  String get apiKey => _apiKey;
  String get nativeLanguage => _nativeLanguage;
  String get targetLanguage => _targetLanguage;
  String get selectedTopic => _selectedTopic;
  String get currentQuestion => _currentQuestion;
  String get feedback => _feedback;
  List<String> get examples => List.unmodifiable(_examples);
  LoadingPhase get loadingPhase => _loadingPhase;
  String get errorMessage => _errorMessage;

  bool get isIdle => _loadingPhase == LoadingPhase.none;
  bool get isTestingKey => _loadingPhase == LoadingPhase.testingKey;
  bool get isGeneratingQuestion => _loadingPhase == LoadingPhase.generatingQ;
  bool get isSubmitting => _loadingPhase == LoadingPhase.submitting;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;
  bool get hasQuestion => _currentQuestion.isNotEmpty;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Load all persisted values from SharedPreferences.
  void loadFromPrefs() {
    _apiKey = _prefs.getString(kPrefApiKey) ?? '';
    _nativeLanguage = _prefs.getString(kPrefNativeLang) ?? 'ar';
    _targetLanguage = _prefs.getString(kPrefTargetLang) ?? 'en';
    _selectedTopic = _prefs.getString(kPrefTopic) ?? kTopics.first;
    notifyListeners();
  }

  // ─── API Key ───────────────────────────────────────────────────────────────

  /// Tests the key with a live API call, saves if valid.
  /// Returns a human-friendly status message (for SnackBar).
  Future<({bool success, String message})> testAndSaveApiKey(
      String rawKey) async {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return (success: false, message: 'Please enter an API key.');
    }
    _setPhase(LoadingPhase.testingKey);
    try {
      await _api.testApiKey(key);
      _apiKey = key;
      await _prefs.setString(kPrefApiKey, key);
      _setPhase(LoadingPhase.none);
      return (success: true, message: '✓ API key verified and saved!');
    } on GeminiServiceException catch (e) {
      _setPhase(LoadingPhase.none);
      return (success: false, message: e.message);
    }
  }

  // ─── Language selection ────────────────────────────────────────────────────

  Future<void> setNativeLanguage(String code) async {
    if (_nativeLanguage == code) return;
    _nativeLanguage = code;
    await _prefs.setString(kPrefNativeLang, code);
    notifyListeners();
  }

  Future<void> setTargetLanguage(String code) async {
    if (_targetLanguage == code) return;
    _targetLanguage = code;
    await _prefs.setString(kPrefTargetLang, code);
    notifyListeners();
  }

  // ─── Topic selection ───────────────────────────────────────────────────────

  /// Saves the topic and immediately generates a new question for it.
  Future<String?> selectTopic(String topic) async {
    _selectedTopic = topic;
    await _prefs.setString(kPrefTopic, topic);
    _clearSession();
    notifyListeners();
    return generateQuestion();
  }

  // ─── Question generation ───────────────────────────────────────────────────

  /// Generates a new question from the AI.
  /// Returns an error message string on failure, null on success.
  Future<String?> generateQuestion() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _setPhase(LoadingPhase.generatingQ);
    _clearSession();
    try {
      final question = await _api.generateQuestion(
        apiKey: _apiKey,
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetLanguage: languageLabelFromCode(_targetLanguage),
        topic: _selectedTopic,
      );
      _currentQuestion = question;
      _setPhase(LoadingPhase.none);
      return null;
    } on GeminiServiceException catch (e) {
      _errorMessage = e.message;
      _setPhase(LoadingPhase.none);
      return e.message;
    }
  }

  // ─── Answer submission ─────────────────────────────────────────────────────

  /// Submits the user's answer for analysis.
  /// Returns an error message on failure, null on success.
  Future<String?> submitAnswer(String answer) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    if (!hasQuestion) return 'Please select a topic to get a question first.';
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return 'Please write your answer first.';

    _setPhase(LoadingPhase.submitting);
    _feedback = '';
    _examples = ['', '', ''];
    notifyListeners();

    try {
      final analysis = await _api.analyzeAnswer(
        apiKey: _apiKey,
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetLanguage: languageLabelFromCode(_targetLanguage),
        topic: _selectedTopic,
        question: _currentQuestion,
        answer: trimmed,
      );
      _feedback = analysis.feedback;
      _examples = List<String>.from(analysis.examples);
      _setPhase(LoadingPhase.none);
      return null;
    } on GeminiServiceException catch (e) {
      _errorMessage = e.message;
      _setPhase(LoadingPhase.none);
      return e.message;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setPhase(LoadingPhase phase) {
    _loadingPhase = phase;
    notifyListeners();
  }

  void _clearSession() {
    _currentQuestion = '';
    _feedback = '';
    _examples = ['', '', ''];
    _errorMessage = '';
  }
}
