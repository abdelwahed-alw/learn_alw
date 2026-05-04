// lib/onboarding_screen.dart
// First-run onboarding: API key setup → level selection or proficiency test.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'home_screen.dart';
import 'proficiency_test_screen.dart';
import 'ui_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  final TextEditingController _apiKeyCtrl = TextEditingController();

  bool _isKeyVisible = false;
  bool _keyValidated = false;
  bool _languageSelected = false;
  String? _keyMessage;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: kPremiumCurve);
    _ctrl.forward();

    // Pre-fill if API key already exists
    final model = context.read<AppStateModel>();
    if (model.hasApiKey) {
      _apiKeyCtrl.text = model.apiKey;
      _keyValidated = true;
    }
    
    // Check if the user previously selected a language (heuristic: onboarding done or some other flag,
    // actually they select language first time, so we just force them to select unless already selected somehow)
    // To make it simple, we require language selection every first run.
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) {
      final lang = context.read<AppStateModel>().nativeLanguage;
      setState(() => _keyMessage = t('pleaseEnterKey', lang));
      return;
    }
    FocusScope.of(context).unfocus();
    final model = context.read<AppStateModel>();
    final result = await model.testAndSaveApiKey(key);
    if (mounted) {
      setState(() {
        _keyValidated = result.success;
        // The message returned by the service might not be localized easily without rewriting the service,
        // so we can fallback to the english/service returned ones or try to map them.
        _keyMessage = result.success ? t('apiKeyVerified', model.nativeLanguage) : result.message;
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: kPremiumCurve),
          child: child,
        ),
      ),
    );
  }

  void _navigateToTest() {
    final lang = context.read<AppStateModel>().nativeLanguage;
    if (!_keyValidated) {
      setState(() => _keyMessage = t('pleaseValidateKey', lang));
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProficiencyTestScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: kPremiumCurve)),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _selectLevel(String level) async {
    final lang = context.read<AppStateModel>().nativeLanguage;
    if (!_keyValidated) {
      setState(() => _keyMessage = t('pleaseValidateKey', lang));
      return;
    }
    HapticFeedback.mediumImpact();
    final model = context.read<AppStateModel>();
    await model.setProficiencyLevel(level);
    await model.completeOnboarding();
    if (mounted) _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppStateModel>().nativeLanguage;
    
    return Scaffold(
      backgroundColor: kColorBackground,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kColorPrimary.withValues(alpha: 0.15),
                      kColorPrimary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kColorAccent.withValues(alpha: 0.1),
                      kColorAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(lang),
                          const SizedBox(height: 32),
                          // ── Step 0: Language Selection ──
                          _buildLanguageSection(lang),
                          const SizedBox(height: 32),
                          // ── Step 1: API Key ──
                          AnimatedOpacity(
                            opacity: _languageSelected ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 400),
                            child: IgnorePointer(
                              ignoring: !_languageSelected,
                              child: _buildApiKeySection(lang),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // ── Step 2: Level selection (only after API key validated) ──
                          AnimatedOpacity(
                            opacity: (_languageSelected && _keyValidated) ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 400),
                            child: IgnorePointer(
                              ignoring: !(_languageSelected && _keyValidated),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTestCard(lang),
                                  const SizedBox(height: 24),
                                  _buildOrDivider(lang),
                                  const SizedBox(height: 24),
                                  _buildManualSection(lang),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icon/icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t('welcomeTo', lang),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: kColorText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          t('setupApiKey', lang),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: kColorTextMuted,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  // ── Language Section ────────────────────────────────────────────────────────
  Widget _buildLanguageSection(String lang) {
    final model = context.watch<AppStateModel>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _languageSelected
              ? Colors.green.withValues(alpha: 0.4)
              : kColorBorder.withValues(alpha: 0.6),
        ),
        boxShadow: [
          if (_languageSelected)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _languageSelected
                      ? Colors.green.withValues(alpha: 0.15)
                      : kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _languageSelected
                      ? Icons.check_circle_rounded
                      : Icons.language_rounded,
                  size: 18,
                  color: _languageSelected ? Colors.green : kColorPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('selectLanguage', lang),
                      style: const TextStyle(
                        color: kColorText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      t('selectLanguageDesc', lang).replaceAll('\n', ' '),
                      style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_languageSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t('ready', lang),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Dropdown for language selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kColorBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kColorBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _languageSelected ? model.nativeLanguage : null,
                hint: Text(t('selectLanguage', lang)),
                isExpanded: true,
                dropdownColor: kColorSurface,
                icon: const Icon(Icons.arrow_drop_down, color: kColorTextMuted),
                style: const TextStyle(color: kColorText, fontSize: 15),
                items: kSupportedLanguages.map((l) {
                  final code = l['code']!;
                  final name = kLanguageNativeNames[code] ?? l['label']!;
                  final flag = kLanguageFlags[code] ?? '🌐';
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text('$flag  $name'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    model.setNativeLanguage(val);
                    setState(() {
                      _languageSelected = true;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── API Key Section ─────────────────────────────────────────────────────────
  Widget _buildApiKeySection(String lang) {
    final model = context.watch<AppStateModel>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _keyValidated
              ? Colors.green.withValues(alpha: 0.4)
              : kColorBorder.withValues(alpha: 0.6),
        ),
        boxShadow: [
          if (_keyValidated)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _keyValidated
                      ? Colors.green.withValues(alpha: 0.15)
                      : kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _keyValidated
                      ? Icons.check_circle_rounded
                      : Icons.key_rounded,
                  size: 18,
                  color: _keyValidated ? Colors.green : kColorPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _keyValidated ? t('apiKeyVerified', lang) : t('step1ApiKey', lang),
                      style: const TextStyle(
                        color: kColorText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      t('apiKeyRequired', lang),
                      style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_keyValidated)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t('ready', lang),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: !_isKeyVisible,
            style: const TextStyle(color: kColorText, fontSize: 14),
            decoration: InputDecoration(
              hintText: t('pasteApiKey', lang),
              hintStyle: TextStyle(
                color: kColorTextMuted.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              fillColor: kColorBackground,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.vpn_key_rounded,
                  size: 16, color: kColorTextMuted.withValues(alpha: 0.6)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isKeyVisible = !_isKeyVisible),
                    child: Icon(
                      _isKeyVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: kColorTextMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: model.isTestingKey ? null : _validateApiKey,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: model.isTestingKey
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            t('validateSave', lang),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_keyMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _keyMessage!,
              style: TextStyle(
                color: _keyValidated ? Colors.green : kColorError,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          // ── Help Guide ──
          if (!_keyValidated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kColorBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kColorBorder.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 16, color: kColorAccent.withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Text(
                        t('howToGetKey', lang),
                        style: const TextStyle(
                          color: kColorAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _HelpStep(number: '1', text: t('helpStep1', lang)),
                  const SizedBox(height: 6),
                  _HelpStep(number: '2', text: t('helpStep2', lang)),
                  const SizedBox(height: 6),
                  _HelpStep(number: '3', text: t('helpStep3', lang)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(kYoutubeTutorialUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kColorPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kColorPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_rounded,
                              size: 18, color: kColorPrimary.withValues(alpha: 0.8)),
                          const SizedBox(width: 8),
                          Text(
                            t('playTutorial', lang),
                            style: TextStyle(
                              color: kColorPrimary.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestCard(String lang) {
    return GestureDetector(
      onTap: _navigateToTest,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: kPrimaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('takeTest', lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t('testDesc', lang),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t('testDescLong', lang),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider(String lang) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                kColorBorder.withValues(alpha: 0.0),
                kColorBorder,
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t('orChooseManually', lang).toUpperCase(),
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                kColorBorder,
                kColorBorder.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('selectYourLevel', lang),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kColorText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        ...kCefrLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final lvl = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 80)),
            curve: kPremiumCurve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelCard(
                code: lvl['code']!,
                label: lvl['label']!,
                emoji: lvl['emoji']!,
                description: lvl['description']!,
                onTap: () => _selectLevel(lvl['code']!),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Level Card ───────────────────────────────────────────────────────────────
class _LevelCard extends StatefulWidget {
  final String code;
  final String label;
  final String emoji;
  final String description;
  final VoidCallback onTap;

  const _LevelCard({
    required this.code,
    required this.label,
    required this.emoji,
    required this.description,
    required this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: kPremiumCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) async {
        await _ctrl.reverse();
        if (mounted) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              // Emoji badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: kPrimaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: kColorText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: kColorTextMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: kColorTextMuted.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Help Step ────────────────────────────────────────────────────────────────
class _HelpStep extends StatelessWidget {
  final String number;
  final String text;
  const _HelpStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: kColorAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: kColorAccent.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: kColorTextMuted.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
