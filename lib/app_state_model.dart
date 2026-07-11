// lib/app_state_model.dart

import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

enum LoadingPhase {
  none,
  testingKey,
  generatingQ,
  submitting,
  translating,
}

enum AppMode { practice, ielts, beginner, categories }

enum IeltsExerciseType { fillBlanks, sentenceCompletion, writingPractice }

class AppStateModel extends ChangeNotifier {
  AppStateModel(this._prefs) : _secureStorage = const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final GeminiApiService _api = GeminiApiService();

  // ── Persisted settings ───────────────────────────────────────────────────
  String _activationCode = '';
  static final encrypt.Key _aesKey = encrypt.Key.fromUtf8('SaLearnAppSecretKey_32CharsLong!');
  static final encrypt.IV _aesIv = encrypt.IV.fromUtf8('SaLearnInitVect!');

  String _decryptActivationCode(String code) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_aesKey, mode: encrypt.AESMode.cbc));
      return encrypter.decrypt64(code, iv: _aesIv);
    } catch (_) {
      return '';
    }
  }
  String _nativeLanguage = 'en';
  String _targetLanguage = 'en';
  String _selectedTopic = kTopics.first;
  String _proficiencyLevel = 'B1';
  bool _onboardingDone = false;
  bool _isDarkMode = true;
  bool _hasSelectedTheme = false;
  bool _showTranslationFab = true;

  // ── Session state ────────────────────────────────────────────────────────
  String _currentQuestion = '';
  String _feedback = '';
  List<String> _examples = ['', '', ''];
  LoadingPhase _loadingPhase = LoadingPhase.none;
  String _errorMessage = '';
  String _lastUserAnswer = '';
  String _nextQuestionPreview = '';
  String _translationResult = '';

  // ── Progress tracking ────────────────────────────────────────────────────
  int _totalExercisesDone = 0;
  Map<String, int> _topicProgress = {};
  Map<String, int> _categoryProgress = {};
  DateTime? _lastActiveDate;
  int _streakCount = 0;

  // ── App mode ─────────────────────────────────────────────────────────────
  AppMode _appMode = AppMode.practice;

  // ── Last accessed mode (for Continue Learning routing) ───────────────────
  AppMode _lastAccessedMode = AppMode.practice;

  // ── IELTS state ──────────────────────────────────────────────────────────
  IeltsExerciseType _ieltsExerciseType = IeltsExerciseType.fillBlanks;
  bool _ieltsLoading = false;
  String _ieltsPassage = '';
  String _ieltsCorrectAnswer = '';
  List<String> _ieltsOptions = [];
  String _ieltsExplanation = '';
  String _ieltsUserAnswer = '';
  String _ieltsFeedback = '';
  double _ieltsBandScore = 0;
  List<String> _ieltsCorrections = [];
  Map<String, String> _ieltsVocabSuggestions = {};
  String _ieltsSuggestedCompletion = '';
  bool _ieltsSentenceCorrect = false;
  String _ieltsPromptOrStart = '';

  // ── Beginner mode state ──────────────────────────────────────────────────
  bool _beginnerLoading = false;
  String _beginnerTargetWord = '';
  String _beginnerSentence = '';
  List<Map<String, String>> _beginnerVocabulary = [];
  List<BeginnerNewWord> _beginnerCurrentNewWords = [];
  String _beginnerError = '';

  // ─── Getters ───────────────────────────────────────────────────────────────
  String get nativeLanguage => _nativeLanguage;
  String get targetLanguage => _targetLanguage;
  String get selectedTopic => _selectedTopic;
  String get proficiencyLevel => _proficiencyLevel;
  bool get isOnboardingDone => _onboardingDone;
  String get currentQuestion => _currentQuestion;
  String get feedback => _feedback;
  List<String> get examples => List.unmodifiable(_examples);
  LoadingPhase get loadingPhase => _loadingPhase;
  String get errorMessage => _errorMessage;
  String get lastUserAnswer => _lastUserAnswer;
  String get nextQuestionPreview => _nextQuestionPreview;
  String get translationResult => _translationResult;

  AppMode get lastAccessedMode => _lastAccessedMode;

  int get totalExercisesDone => _totalExercisesDone;
  Map<String, int> get topicProgress => Map.unmodifiable(_topicProgress);
  DateTime? get lastActiveDate => _lastActiveDate;
  int get streakDays => _calculateStreak();
  double get overallProgressPercent => _topicProgress.isEmpty
      ? 0.0
      : (_topicProgress.values.fold<int>(0, (a, b) => a + b) /
              (_topicProgress.length * 10))
          .clamp(0.0, 1.0);

  double _categoryPct(String cat) =>
      ((_categoryProgress[cat] ?? 0) / 10.0).clamp(0.0, 1.0);

  double get writingProgress => _categoryPct('writing');
  double get grammarProgress => _categoryPct('grammar');
  double get vocabularyProgress => _categoryPct('vocabulary');
  double get readingProgress => _categoryPct('reading');
  double get speakingProgress => _categoryPct('speaking');
  double get listeningProgress => _categoryPct('listening');

  bool get isIdle => _loadingPhase == LoadingPhase.none;
  bool get isTestingKey => _loadingPhase == LoadingPhase.testingKey;
  bool get isGeneratingQuestion => _loadingPhase == LoadingPhase.generatingQ;
  bool get isSubmitting => _loadingPhase == LoadingPhase.submitting;
  bool get isTranslating => _loadingPhase == LoadingPhase.translating;
  String get apiKey => _decryptActivationCode(_activationCode);
  bool get hasApiKey => _activationCode.trim().isNotEmpty;
  bool get isDarkMode => _isDarkMode;
  bool get hasSelectedTheme => _hasSelectedTheme;
  bool get showTranslationFab => _showTranslationFab;
  bool get hasQuestion => _currentQuestion.isNotEmpty;

  // ── Mode getters ────────────────────────────────────────────────────────────
  AppMode get appMode => _appMode;
  IeltsExerciseType get ieltsExerciseType => _ieltsExerciseType;
  bool get ieltsLoading => _ieltsLoading;
  String get ieltsPassage => _ieltsPassage;
  String get ieltsCorrectAnswer => _ieltsCorrectAnswer;
  List<String> get ieltsOptions => List.unmodifiable(_ieltsOptions);
  String get ieltsExplanation => _ieltsExplanation;
  String get ieltsUserAnswer => _ieltsUserAnswer;
  String get ieltsFeedback => _ieltsFeedback;
  double get ieltsBandScore => _ieltsBandScore;
  List<String> get ieltsCorrections => List.unmodifiable(_ieltsCorrections);
  Map<String, String> get ieltsVocabSuggestions =>
      Map.unmodifiable(_ieltsVocabSuggestions);
  String get ieltsSuggestedCompletion => _ieltsSuggestedCompletion;
  bool get ieltsSentenceCorrect => _ieltsSentenceCorrect;
  String get ieltsPromptOrStart => _ieltsPromptOrStart;
  bool get ieltsHasExercise =>
      _ieltsPassage.isNotEmpty || _ieltsPromptOrStart.isNotEmpty;

  bool get beginnerLoading => _beginnerLoading;
  String get beginnerTargetWord => _beginnerTargetWord;
  String get beginnerSentence => _beginnerSentence;
  List<Map<String, String>> get beginnerVocabulary =>
      List.unmodifiable(_beginnerVocabulary);
  List<BeginnerNewWord> get beginnerCurrentNewWords =>
      List.unmodifiable(_beginnerCurrentNewWords);
  String get beginnerError => _beginnerError;
  bool get beginnerHasSentence => _beginnerSentence.isNotEmpty;

  // ─── Initialization ────────────────────────────────────────────────────────
  void loadFromPrefs() {
    _nativeLanguage = _prefs.getString(kPrefNativeLang) ?? 'en';
    _targetLanguage = _prefs.getString(kPrefTargetLang) ?? 'en';
    _selectedTopic = _prefs.getString(kPrefTopic) ?? kTopics.first;
    _proficiencyLevel = _prefs.getString(kPrefLevel) ?? 'B1';
    _onboardingDone = _prefs.getBool(kPrefOnboarding) ?? false;
    _isDarkMode = _prefs.getBool(kPrefIsDarkMode) ?? true;
    _hasSelectedTheme = _prefs.getBool(kPrefHasSelectedTheme) ?? false;
    _showTranslationFab = _prefs.getBool(kPrefIsFabVisible) ?? true;
    _loadBeginnerVocabularyFromPrefs();
    loadProgress();
    notifyListeners();
    // Fire-and-forget: load API key from secure storage asynchronously
    unawaited(_loadApiKey());
  }

  Future<void> _loadApiKey() async {
    try {
      _activationCode = await _secureStorage.read(key: kPrefActivationCode) ?? '';
      notifyListeners();
    } catch (_) {
      _activationCode = '';
    }
  }

  void _loadBeginnerVocabularyFromPrefs() {
    final raw = _prefs.getString(kPrefBeginnerVocab);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _beginnerVocabulary = decoded.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'word': (m['word'] as String? ?? ''),
            'meaning': (m['meaning'] as String? ?? ''),
          };
        }).toList();
        _deduplicateBeginnerVocabulary();
      } catch (_) {
        _beginnerVocabulary = [];
      }
    }
  }

  void _deduplicateBeginnerVocabulary() {
    final seen = <String>{};
    final unique = <Map<String, String>>[];
    for (final entry in _beginnerVocabulary) {
      final key = (entry['word'] ?? '').trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(entry);
    }
    if (unique.length != _beginnerVocabulary.length) {
      _beginnerVocabulary = unique;
      _saveBeginnerVocabulary();
    }
  }

  // ─── Onboarding ────────────────────────────────────────────────────────────
  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _prefs.setBool(kPrefOnboarding, true);
    notifyListeners();
  }

  // ─── Theme ──────────────────────────────────────────────────────────────────
  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(kPrefIsDarkMode, isDark);
    notifyListeners();
  }

  Future<void> completeThemeSelection(bool isDark) async {
    _isDarkMode = isDark;
    _hasSelectedTheme = true;
    await _prefs.setBool(kPrefIsDarkMode, isDark);
    await _prefs.setBool(kPrefHasSelectedTheme, true);
    notifyListeners();
  }

  // ─── FAB Visibility ─────────────────────────────────────────────────────────
  Future<void> setFabVisibility(bool visible) async {
    _showTranslationFab = visible;
    await _prefs.setBool(kPrefIsFabVisible, visible);
    notifyListeners();
  }

  // ─── Proficiency Level ─────────────────────────────────────────────────────
  Future<void> setProficiencyLevel(String level) async {
    _proficiencyLevel = level;
    await _prefs.setString(kPrefLevel, level);
    _clearSession();
    notifyListeners();
  }

  // ─── Activation Code ───────────────────────────────────────────────────────
  Future<({bool success, String message})> testAndSaveApiKey(
      String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      return (success: false, message: 'enterActivationCode'.tr());
    }
    final apiKey = _decryptActivationCode(code);
    if (apiKey.isEmpty) {
      return (success: false, message: 'invalidActivationCode'.tr());
    }
    _setPhase(LoadingPhase.testingKey);
    try {
      await _api.testApiKey(apiKey);
      _activationCode = code;
      await _secureStorage.write(key: kPrefActivationCode, value: code);
      _setPhase(LoadingPhase.none);
      return (success: true, message: 'activationCodeVerified'.tr());
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
    _beginnerVocabulary.clear();
    await _prefs.remove(kPrefBeginnerVocab);
    notifyListeners();
  }

  /// Swaps the native and target languages and persists the change.
  Future<void> swapLanguages() async {
    final temp = _nativeLanguage;
    _nativeLanguage = _targetLanguage;
    _targetLanguage = temp;
    await _prefs.setString(kPrefNativeLang, _nativeLanguage);
    await _prefs.setString(kPrefTargetLang, _targetLanguage);
    _clearSession();
    notifyListeners();
  }

  // ─── Progress Tracking ──────────────────────────────────────────────────────

  void loadProgress() {
    _totalExercisesDone = _prefs.getInt(kPrefTotalExercises) ?? 0;
    final raw = _prefs.getString(kPrefTopicProgress);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        _topicProgress = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        _topicProgress = {};
      }
    }
    final lastActive = _prefs.getInt(kPrefLastActive);
    if (lastActive != null) {
      _lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActive);
    }
    _streakCount = _prefs.getInt(kPrefStreak) ?? 0;
    final catRaw = _prefs.getString(kPrefCategoryProgress);
    if (catRaw != null && catRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(catRaw) as Map<String, dynamic>;
        _categoryProgress =
            decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        _categoryProgress = {};
      }
    }
    final savedMode = _prefs.getInt(kPrefLastMode);
    if (savedMode != null &&
        savedMode >= 0 &&
        savedMode < AppMode.values.length) {
      _lastAccessedMode = AppMode.values[savedMode];
    }
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    await _prefs.setInt(kPrefTotalExercises, _totalExercisesDone);
    await _prefs.setString(kPrefTopicProgress, jsonEncode(_topicProgress));
    await _prefs.setInt(kPrefLastActive, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setInt(kPrefStreak, _streakCount);
    await _prefs.setInt(kPrefLastMode, _lastAccessedMode.index);
    await _prefs.setString(kPrefCategoryProgress, jsonEncode(_categoryProgress));
  }

  void incrementCategoryProgress(String category) {
    _categoryProgress[category] = (_categoryProgress[category] ?? 0) + 1;
    _saveProgress();
    notifyListeners();
  }

  void incrementExerciseProgress(String topic) {
    _totalExercisesDone++;
    _topicProgress[topic] = (_topicProgress[topic] ?? 0) + 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastActiveDate != null) {
      final lastDay = DateTime(
        _lastActiveDate!.year,
        _lastActiveDate!.month,
        _lastActiveDate!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // same day — streak unchanged
      } else if (diff == 1) {
        _streakCount++;
      } else {
        _streakCount = 1;
      }
    } else {
      _streakCount = 1;
    }
    _lastActiveDate = now;
    _lastAccessedMode = _appMode;

    _saveProgress();
    notifyListeners();
  }

  int _calculateStreak() {
    if (_lastActiveDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      _lastActiveDate!.year,
      _lastActiveDate!.month,
      _lastActiveDate!.day,
    );
    final diff = today.difference(lastDay).inDays;
    if (diff <= 1) return _streakCount;
    return 0;
  }

  // ─── App Mode ────────────────────────────────────────────────────────────────
  void setAppMode(AppMode mode) {
    if (_appMode == mode) return;
    _appMode = mode;
    _lastAccessedMode = mode;
    _prefs.setInt(kPrefLastMode, mode.index);
    notifyListeners();
  }

  void setIeltsExerciseType(IeltsExerciseType type) {
    _ieltsExerciseType = type;
    _clearIeltsSession();
    notifyListeners();
  }

  // ─── Topic selection ───────────────────────────────────────────────────────
  Future<String?> selectTopic(String topic) async {
    _selectedTopic = topic;
    await _prefs.setString(kPrefTopic, topic);
    _clearSession();
    notifyListeners();
    return generateQuestion();
  }

  // ─── IELTS Exercise Generation ──────────────────────────────────────────────

  Future<String?> generateIeltsFillBlank() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsLoading = true;
    _clearIeltsSession();
    _ieltsExerciseType = IeltsExerciseType.fillBlanks;
    notifyListeners();

    try {
      final exercise = await _api.generateIeltsFillBlank(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
      );
      _ieltsPassage = exercise.passage;
      _ieltsCorrectAnswer = exercise.blankWord;
      _ieltsOptions = exercise.options;
      _ieltsExplanation = exercise.explanation;
      _ieltsLoading = false;
      notifyListeners();
      return null;
    } on GeminiServiceException catch (e) {
      _ieltsLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> generateIeltsSentenceStart() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsLoading = true;
    _clearIeltsSession();
    _ieltsExerciseType = IeltsExerciseType.sentenceCompletion;
    notifyListeners();

    try {
      final sentenceStart = await _api.generateIeltsSentenceStart(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
      );
      _ieltsPromptOrStart = sentenceStart;
      _ieltsLoading = false;
      notifyListeners();
      return null;
    } on GeminiServiceException catch (e) {
      _ieltsLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> generateIeltsWritingPrompt() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsLoading = true;
    _clearIeltsSession();
    _ieltsExerciseType = IeltsExerciseType.writingPractice;
    notifyListeners();

    try {
      final prompt = await _api.generateIeltsWritingPrompt(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
      );
      _ieltsPromptOrStart = prompt;
      _ieltsLoading = false;
      notifyListeners();
      return null;
    } on GeminiServiceException catch (e) {
      _ieltsLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  // ─── IELTS Submission ────────────────────────────────────────────────────────

  Future<String?> submitIeltsFillBlank(String answer) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsUserAnswer = answer;
    _ieltsFeedback = answer == _ieltsCorrectAnswer
        ? '✓ Correct!'
        : '✗ Incorrect. The correct answer is: $_ieltsCorrectAnswer';
    notifyListeners();
    incrementExerciseProgress(_selectedTopic);
    return null;
  }

  Future<String?> submitIeltsSentenceCompletion(String completion) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsLoading = true;
    _ieltsUserAnswer = completion;
    notifyListeners();

    try {
      final eval = await _api.evaluateIeltsSentenceCompletion(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        sentenceStart: _ieltsPromptOrStart,
        userCompletion: completion,
      );
      _ieltsFeedback = eval.feedback;
      _ieltsSentenceCorrect = eval.isCorrect;
      _ieltsSuggestedCompletion = eval.suggestedCompletion;
      _ieltsLoading = false;
      notifyListeners();
      incrementExerciseProgress(_selectedTopic);
      return null;
    } on GeminiServiceException catch (e) {
      _ieltsLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> submitIeltsWriting(String answer) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _ieltsLoading = true;
    _ieltsUserAnswer = answer;
    notifyListeners();

    try {
      final eval = await _api.evaluateIeltsWriting(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        prompt: _ieltsPromptOrStart,
        userAnswer: answer,
      );
      _ieltsFeedback = eval.feedback;
      _ieltsBandScore = eval.bandScore;
      _ieltsCorrections = eval.corrections;
      _ieltsVocabSuggestions = eval.vocabularySuggestions;
      _ieltsLoading = false;
      notifyListeners();
      incrementExerciseProgress(_selectedTopic);
      return null;
    } on GeminiServiceException catch (e) {
      _ieltsLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  // ─── Question generation ───────────────────────────────────────────────────
  Future<String?> generateQuestion() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _setPhase(LoadingPhase.generatingQ);
    _clearSession();
    try {
      final question = await _api.generateQuestion(
        apiKey: apiKey,
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetLanguage: languageLabelFromCode(_targetLanguage),
        topic: _selectedTopic,
        level: _proficiencyLevel,
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
  Future<String?> submitAnswer(String answer) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    if (!hasQuestion) return 'Please select a topic to get a question first.';
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return 'Please write your answer first.';

    _lastUserAnswer = trimmed;

    _setPhase(LoadingPhase.submitting);
    _feedback = '';
    _examples = ['', '', ''];
    _nextQuestionPreview = '';
    notifyListeners();

    try {
      final analysis = await _api.analyzeAnswer(
        apiKey: apiKey,
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetLanguage: languageLabelFromCode(_targetLanguage),
        topic: _selectedTopic,
        question: _currentQuestion,
        answer: trimmed,
        level: _proficiencyLevel,
      );
      _feedback = analysis.feedback;
      _examples = List<String>.from(analysis.examples);
      _setPhase(LoadingPhase.none);
      incrementExerciseProgress(_selectedTopic);

      // Auto-generate next question preview in background
      _generateNextQuestionPreview();

      return null;
    } on GeminiServiceException catch (e) {
      _errorMessage = e.message;
      _setPhase(LoadingPhase.none);
      return e.message;
    }
  }

  // ─── Translation ───────────────────────────────────────────────────────────
  Future<String?> translateText(String text) async {
    if (!hasApiKey) return 'Please configure your API key first.';
    if (text.trim().isEmpty) return 'Nothing to translate.';

    _translationResult = '';
    _setPhase(LoadingPhase.translating);

    try {
      final result = await _api.translateText(
        apiKey: apiKey,
        text: text,
        fromLanguage: languageLabelFromCode(_targetLanguage),
        toLanguage: languageLabelFromCode(_nativeLanguage),
      );
      _translationResult = result;
      _setPhase(LoadingPhase.none);
      return null;
    } on GeminiServiceException catch (e) {
      _setPhase(LoadingPhase.none);
      return e.message;
    }
  }

  void clearTranslation() {
    _translationResult = '';
    notifyListeners();
  }

  // ─── Beginner Mode ──────────────────────────────────────────────────────────

  void loadBeginnerVocabulary() {
    _loadBeginnerVocabularyFromPrefs();
    notifyListeners();
  }

  Future<void> _saveBeginnerVocabulary() async {
    final encoded = jsonEncode(_beginnerVocabulary);
    await _prefs.setString(kPrefBeginnerVocab, encoded);
  }

  Future<String?> generateBeginnerSentence() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    _beginnerLoading = true;
    _clearBeginnerSession();
    notifyListeners();

    try {
      // Determine target word: if no vocab, pick a common first word
      String targetWord;
      if (_beginnerVocabulary.isEmpty) {
        targetWord =
            _targetLanguage == 'en' ? 'eat' : _simpleFirstWord(_targetLanguage);
      } else {
        // Pick a word from the known list to reinforce, or introduce new
        targetWord = _pickNextBeginnerWord();
      }

      final knownWords =
          _beginnerVocabulary.map((e) => e['word'] ?? '').toList();

      final result = await _api.generateBeginnerSentence(
        apiKey: apiKey,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetWord: targetWord,
        knownWords: knownWords,
      );

      _beginnerTargetWord = result.targetWord;
      _beginnerSentence = result.sentence;
      _beginnerCurrentNewWords = result.newWords;

      // Auto-discover words that were already in vocab (no need to show)
      // Only new words that aren't already known will be discoverable
      _beginnerLoading = false;
      notifyListeners();
      incrementExerciseProgress(_selectedTopic);
      return null;
    } on GeminiServiceException catch (e) {
      _beginnerLoading = false;
      _beginnerError = e.message;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> discoverBeginnerWord(String word) async {
    if (!hasApiKey) return 'Please configure your API key first.';

    final clean = word.trim().toLowerCase();
    // Check if already known (ignore case, spacing, and meaning)
    final alreadyKnown = _beginnerVocabulary
        .any((e) => (e['word'] ?? '').trim().toLowerCase() == clean);
    if (alreadyKnown) return null;

    try {
      final meaning = await _api.getWordMeaning(
        apiKey: apiKey,
        word: word,
        targetLanguage: languageLabelFromCode(_targetLanguage),
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
      );

      _beginnerVocabulary.add({
        'word': meaning.word,
        'meaning': meaning.meaning,
      });
      await _saveBeginnerVocabulary();
      notifyListeners();
      incrementExerciseProgress('vocabulary');
      return null;
    } on GeminiServiceException catch (e) {
      return e.message;
    }
  }

  void setBeginnerTargetWord(String word) {
    _beginnerTargetWord = word;
    _beginnerSentence = '';
    _beginnerCurrentNewWords = [];
    notifyListeners();
  }

  String _simpleFirstWord(String lang) {
    // Return basic words in common languages
    const firstWords = {
      'en': 'eat',
      'es': 'comer',
      'fr': 'manger',
      'de': 'essen',
      'it': 'mangiare',
      'pt': 'comer',
      'tr': 'yemek',
      'ar': 'أكل',
      'zh': '吃',
      'ja': '食べる',
    };
    return firstWords[lang] ?? 'eat';
  }

  String _pickNextBeginnerWord() {
    // Cycle through known vocabulary to pick one for reinforcement
    if (_beginnerVocabulary.isEmpty) return _simpleFirstWord(_targetLanguage);
    // Pick a random known word, or if all are well-known, just pick the first
    final index =
        DateTime.now().millisecondsSinceEpoch % _beginnerVocabulary.length;
    return _beginnerVocabulary[index]['word'] ??
        _simpleFirstWord(_targetLanguage);
  }

  // ─── Background preview generation ────────────────────────────────────────
  Future<void> _generateNextQuestionPreview() async {
    try {
      final preview = await _api.generateNextQuestion(
        apiKey: apiKey,
        nativeLanguage: languageLabelFromCode(_nativeLanguage),
        targetLanguage: languageLabelFromCode(_targetLanguage),
        topic: _selectedTopic,
        previousQuestion: _currentQuestion,
        userAnswer: _lastUserAnswer,
        level: _proficiencyLevel,
      );
      _nextQuestionPreview = preview;
      notifyListeners();
    } catch (_) {
      _nextQuestionPreview = '';
    }
  }

  // ─── Contextual next question ──────────────────────────────────────────────
  Future<String?> generateNextQuestion() async {
    if (!hasApiKey) return 'Please configure your API key first.';
    if (_nextQuestionPreview.isEmpty) return 'Next question not ready yet.';

    _currentQuestion = _nextQuestionPreview;
    _nextQuestionPreview = '';
    _clearSessionKeepQuestion();
    notifyListeners();
    return null;
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
    _lastUserAnswer = '';
    _nextQuestionPreview = '';
    _translationResult = '';
  }

  void _clearSessionKeepQuestion() {
    _feedback = '';
    _examples = ['', '', ''];
    _errorMessage = '';
    _nextQuestionPreview = '';
    _translationResult = '';
  }

  void _clearIeltsSession() {
    _ieltsPassage = '';
    _ieltsCorrectAnswer = '';
    _ieltsOptions = [];
    _ieltsExplanation = '';
    _ieltsUserAnswer = '';
    _ieltsFeedback = '';
    _ieltsBandScore = 0;
    _ieltsCorrections = [];
    _ieltsVocabSuggestions = {};
    _ieltsSuggestedCompletion = '';
    _ieltsSentenceCorrect = false;
    _ieltsPromptOrStart = '';
  }

  void _clearBeginnerSession() {
    _beginnerTargetWord = '';
    _beginnerSentence = '';
    _beginnerCurrentNewWords = [];
    _beginnerError = '';
  }
}
