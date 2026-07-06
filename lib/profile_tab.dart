import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'quick_translation_sheet.dart';
import 'ui_strings.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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
          SnackBar(
            content: Text(
                t('couldNotOpenLink',
                    context.read<AppStateModel>().nativeLanguage)),
            backgroundColor: kColorError,
          ),
        );
      }
    }
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    t('changeLevel', state.nativeLanguage),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
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
                  final isSelected =
                      state.proficiencyLevel == lvl['code'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () async {
                        await state
                            .setProficiencyLevel(lvl['code']!);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kColorPrimary.withValues(alpha: 0.1)
                              : kColorBackground,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? kColorPrimary
                                    .withValues(alpha: 0.4)
                                : kColorBorder
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lvl['emoji']!,
                                style:
                                    const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tLevel(lvl['code']!,
                                            state.nativeLanguage),
                                        style: TextStyle(
                                          color: isSelected
                                              ? kColorPrimary
                                              : kColorAccent,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tLevelDesc(lvl['code']!,
                                        state.nativeLanguage),
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
                                child: const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        final lang = state.nativeLanguage;
        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state),
                      const SizedBox(height: 24),
                      _buildApiKeySection(state, lang),
                      const SizedBox(height: 24),
                      _buildLanguageSection(state, lang),
                      const SizedBox(height: 24),
                      _buildLevelSection(state, lang),
                      const SizedBox(height: 24),
                      _buildAppSettings(),
                      const SizedBox(height: 24),
                      _buildQuickTranslation(state, lang),
                      const SizedBox(height: 24),
                      _buildAppInfo(),
                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppStateModel state) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: kPrimaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kColorPrimary.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                color: kColorText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${languageLabelFromCode(state.nativeLanguage)} → ${languageLabelFromCode(state.targetLanguage)}',
              style: TextStyle(
                color: kColorTextMuted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kColorTextMuted.withValues(alpha: 0.8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildApiKeySection(AppStateModel state, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('API KEY'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _apiKeyController,
                obscureText: !_isKeyVisible,
                style: const TextStyle(color: kColorText, fontSize: 13),
                decoration: InputDecoration(
                  hintText: t('pasteApiKey', lang),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: state.loadingPhase == LoadingPhase.testingKey
                    ? null
                    : () => _testAndSaveKey(state),
                child: Container(
                  width: double.infinity,
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
                    child: state.loadingPhase == LoadingPhase.testingKey
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
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t('testAndSave', lang),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _launchYouTube,
                child: Container(
                  width: double.infinity,
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
                      Icon(Icons.play_circle_outline_rounded,
                          color: kColorPrimary, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        t('howToGetKey', lang),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(AppStateModel state, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(t('languages', lang)),
        Container(
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              _LanguageRow(
                label: t('iSpeak', lang),
                icon: Icons.record_voice_over_rounded,
                value: state.nativeLanguage,
                items: kSupportedLanguages,
                onChanged: (val) async {
                  if (val != null) {
                    await state.setNativeLanguage(val);
                    context.setLocale(Locale(val));
                    Phoenix.rebirth(context);
                  }
                },
              ),
              Divider(
                  height: 1,
                  color: kColorBorder.withValues(alpha: 0.5)),
              _LanguageRow(
                label: t('iWantToLearn', lang),
                icon: Icons.school_rounded,
                value: state.targetLanguage,
                items: kSupportedLanguages,
                onChanged: (val) async {
                  if (val != null) {
                    await state.setTargetLanguage(val);
                    Phoenix.rebirth(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSection(AppStateModel state, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(t('proficiency', lang)),
        GestureDetector(
          onTap: () => _showLevelPicker(state),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kColorSurface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: kColorBorder.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
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
                        tLevel(state.proficiencyLevel, lang),
                        style: TextStyle(
                          color:
                              kColorTextMuted.withValues(alpha: 0.8),
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
                  child: Text(
                    t('change', lang),
                    style: const TextStyle(
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

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salearn',
                      style: TextStyle(
                        color: kColorText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'AI Language Tutor',
                      style: TextStyle(
                        color: kColorTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                kAppVersion,
                style: TextStyle(
                  color: kColorTextMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Consumer<AppStateModel>(
      builder: (context, state, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('appSettings'.tr()),
            Container(
              decoration: BoxDecoration(
                color: kColorSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.dark_mode_rounded, color: kColorPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'darkMode'.tr(),
                      style: const TextStyle(
                        color: kColorText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: state.isDarkMode,
                    onChanged: (val) => state.setThemeMode(val),
                    activeTrackColor: kColorPrimary.withValues(alpha: 0.4),
                    activeThumbColor: kColorPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: kColorSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.translate_rounded, color: kColorPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'showTranslationFab'.tr(),
                      style: const TextStyle(
                        color: kColorText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: state.showTranslationFab,
                    onChanged: (val) => state.setFabVisibility(val),
                    activeTrackColor: kColorPrimary.withValues(alpha: 0.4),
                    activeThumbColor: kColorPrimary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickTranslation(AppStateModel state, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('quickTranslation'.tr()),
        GestureDetector(
          onTap: () => showQuickTranslationSheet(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kColorSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kColorBorder.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quickTranslation'.tr(),
                        style: const TextStyle(
                          color: kColorText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'quickTranslation'.tr(),
                        style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'open'.tr(),
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

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Powered by Abdelwahed Abdellaoui',
          style: TextStyle(
            color: kColorTextMuted.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(FontAwesomeIcons.facebook, 'Facebook', 'https://www.facebook.com/profile.php?id=61573168753232'),
            const SizedBox(width: 8),
            _socialIcon(FontAwesomeIcons.instagram, 'Instagram',
                'https://www.instagram.com/abdelwahed_alw?igsh=NTB5ZW02Nzc2MnZi'),
            const SizedBox(width: 8),
            _socialIcon(FontAwesomeIcons.linkedin, 'LinkedIn',
                'https://www.linkedin.com/in/abdellwahed-abdellaoui-923308188'),
            const SizedBox(width: 8),
            _socialIcon(FontAwesomeIcons.github, 'GitHub', 'https://github.com/abdelwahed-alw'),
            const SizedBox(width: 8),
            _socialIcon(FontAwesomeIcons.globe, 'Website', 'https://abdelwahedabdellaoui.pages.dev/'),
          ],
        ),
      ],
    );
  }

  Future<void> _launchSocialUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Widget _socialIcon(FaIconData icon, String label, String url) {
    return GestureDetector(
      onTap: () => _launchSocialUrl(url),
      child: Tooltip(
        message: label,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kColorSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kColorBorder.withValues(alpha: 0.5)),
          ),
          child: Center(child: FaIcon(icon, size: 18, color: kColorTextMuted)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
