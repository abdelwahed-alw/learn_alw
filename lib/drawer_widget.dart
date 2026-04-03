// lib/drawer_widget.dart
// Premium redesigned drawer with refined visual hierarchy,
// topic icons, glassmorphism touches, and smooth micro-interactions.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state_model.dart';
import 'constants.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isKeyVisible = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateModel>();
    _apiKeyController.text = state.apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveKey(AppStateModel state) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an API key.'),
            backgroundColor: kColorError,
          ),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await state.testAndSaveApiKey(key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? kColorPrimary : kColorError,
      ),
    );
  }

  Future<void> _launchYouTube() async {
    final url = Uri.parse(kYoutubeTutorialUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open YouTube link.'),
            backgroundColor: kColorError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      width: 320,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: kColorBackground.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                right: BorderSide(
                  color: kColorBorder.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Consumer<AppStateModel>(
              builder: (context, state, _) {
                return SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _buildHeader(state),
                      Expanded(
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          children: [
                            _buildApiKeySection(state),
                            const SizedBox(height: 24),
                            _buildLanguageSection(state),
                            const SizedBox(height: 24),
                            _buildLevelSection(state),
                            const SizedBox(height: 24),
                            _buildTopicSection(state),
                          ],
                        ),
                      ),
                      _buildFooter(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppStateModel state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: kDrawerGradient,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
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
            bottom: -30,
            left: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kColorAccent.withValues(alpha: 0.08),
                    kColorAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // App icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kColorPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salearn',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: kColorText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI Language Tutor',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: kColorTextMuted,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // API status dot
                  _ApiStatusDot(isConnected: state.hasApiKey),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: kColorPrimary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kColorTextMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kColorBorder.withValues(alpha: 0.6),
                    kColorBorder.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── API Key Section ───────────────────────────────────────────────────────
  Widget _buildApiKeySection(AppStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('API KEY', Icons.vpn_key_rounded),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Key input with visibility toggle
              TextField(
                controller: _apiKeyController,
                obscureText: !_isKeyVisible,
                style: const TextStyle(color: kColorText, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste your Gemini key…',
                  hintStyle: TextStyle(
                    color: kColorTextMuted.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  fillColor: kColorBackground,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    size: 16,
                    color: kColorTextMuted.withValues(alpha: 0.6),
                  ),
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
                      GestureDetector(
                        onTap: _apiKeyController.clear,
                        child: const Icon(
                          Icons.close_rounded,
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
              // Save button
              _GradientButton(
                label: 'Test & Save',
                icon: Icons.check_circle_outline_rounded,
                isLoading: state.loadingPhase == LoadingPhase.testingKey,
                onTap: state.loadingPhase == LoadingPhase.testingKey
                    ? null
                    : () => _testAndSaveKey(state),
              ),
              const SizedBox(height: 8),
              // Help link
              _GhostButton(
                label: 'How to get an API key',
                icon: Icons.play_circle_outline_rounded,
                onTap: _launchYouTube,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Language Section ──────────────────────────────────────────────────────
  Widget _buildLanguageSection(AppStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('LANGUAGES', Icons.translate_rounded),
        Container(
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _LanguageRow(
                label: 'I speak',
                icon: Icons.record_voice_over_rounded,
                value: state.nativeLanguage,
                items: kSupportedLanguages,
                onChanged: (val) {
                  if (val != null) state.setNativeLanguage(val);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: kColorBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: kColorPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          size: 14,
                          color: kColorPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: kColorBorder.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _LanguageRow(
                label: 'I want to learn',
                icon: Icons.school_rounded,
                value: state.targetLanguage,
                items: kSupportedLanguages,
                onChanged: (val) {
                  if (val != null) state.setTargetLanguage(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  // ── Proficiency Level Section ──────────────────────────────────────────
  Widget _buildLevelSection(AppStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PROFICIENCY', Icons.bar_chart_rounded),
        GestureDetector(
          onTap: () => _showLevelPicker(state),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kColorSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Level emoji
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      levelEmoji(state.proficiencyLevel),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.proficiencyLevel,
                        style: const TextStyle(
                          color: kColorText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        levelLabel(state.proficiencyLevel),
                        style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: kColorPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLevelPicker(AppStateModel state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: kColorSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Change Level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: kColorText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: kColorTextMuted, size: 22),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                shrinkWrap: true,
                children: kCefrLevels.map((lvl) {
                  final isSelected = state.proficiencyLevel == lvl['code'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () async {
                        await state.setProficiencyLevel(lvl['code']!);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kColorPrimary.withValues(alpha: 0.1)
                              : kColorBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? kColorPrimary.withValues(alpha: 0.4)
                                : kColorBorder.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lvl['emoji']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        lvl['code']!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? kColorPrimary
                                              : kColorText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        lvl['label']!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? kColorPrimary
                                              : kColorAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lvl['description']!,
                                    style: TextStyle(
                                      color: kColorTextMuted
                                          .withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  gradient: kPrimaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Topic Section ─────────────────────────────────────────────────────────
  Widget _buildTopicSection(AppStateModel state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('STUDY TOPIC', Icons.menu_book_rounded),
        Container(
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: kTopics.asMap().entries.map((entry) {
              final index = entry.key;
              final topic = entry.value;
              final isSelected = state.selectedTopic == topic;
              final isLast = index == kTopics.length - 1;
              final icon =
                  kTopicIcons[topic] ?? Icons.article_outlined;

              return Column(
                children: [
                  _TopicTile(
                    topic: topic,
                    icon: icon,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      state.selectTopic(topic);
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 1,
                        color: kColorBorder.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: kColorBorder.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Salearn v1.0.0',
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '·',
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'by Abdelwahed',
            style: TextStyle(
              color: kColorTextMuted.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kColorPrimary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── API Status Indicator ─────────────────────────────────────────────────────
class _ApiStatusDot extends StatelessWidget {
  final bool isConnected;
  const _ApiStatusDot({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isConnected ? 'API Connected' : 'No API Key',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
              : kColorError.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF2ECC71).withValues(alpha: 0.3)
                : kColorError.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isConnected ? const Color(0xFF2ECC71) : kColorError,
                boxShadow: [
                  BoxShadow(
                    color: (isConnected
                            ? const Color(0xFF2ECC71)
                            : kColorError)
                        .withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isConnected
                    ? const Color(0xFF2ECC71)
                    : kColorError,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
      onTapDown: widget.onTap != null
          ? (_) {
              HapticFeedback.lightImpact();
              _ctrl.forward();
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) async {
              await _ctrl.reverse();
              if (mounted) widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 15, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Ghost Button ─────────────────────────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: kColorBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorPrimary, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: kColorAccent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language Row ─────────────────────────────────────────────────────────────
class _LanguageRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<Map<String, String>> items;
  final ValueChanged<String?> onChanged;

  const _LanguageRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kColorTextMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: kColorTextMuted.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: kColorBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kColorBorder.withValues(alpha: 0.5),
              ),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: kColorPrimary, size: 18),
              dropdownColor: kColorSurface,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                color: kColorAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              onChanged: onChanged,
              items: items.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['label']!),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Topic Tile ───────────────────────────────────────────────────────────────
class _TopicTile extends StatefulWidget {
  final String topic;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<_TopicTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        if (mounted) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: kPremiumCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? kColorPrimary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Topic icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: kPremiumCurve,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? kColorPrimary.withValues(alpha: 0.15)
                      : kColorBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected ? kColorPrimary : kColorTextMuted,
                ),
              ),
              const SizedBox(width: 12),
              // Topic name
              Expanded(
                child: Text(
                  widget.topic,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected ? kColorPrimary : kColorAccent,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              // Selection indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: widget.isSelected
                    ? Container(
                        key: const ValueKey('selected'),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: kPrimaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kColorPrimary.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 13, color: Colors.white),
                      )
                    : const SizedBox(
                        key: ValueKey('unselected'), width: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}