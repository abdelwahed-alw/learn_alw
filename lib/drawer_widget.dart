// lib/drawer_widget.dart

import 'package:flutter/material.dart';
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
    try {
      await state.testAndSaveApiKey(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key verified and saved!'),
            backgroundColor: kColorPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kColorError),
        );
      }
    }
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
      backgroundColor: kColorBackground,
      width: 320,
      child: Consumer<AppStateModel>(
        builder: (context, state, _) {
          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      _buildSectionLabel('API KEY', Icons.vpn_key_rounded),
                      const SizedBox(height: 10),
                      _buildApiKeyCard(state),
                      const SizedBox(height: 20),
                      _buildSectionLabel('LANGUAGES', Icons.translate_rounded),
                      const SizedBox(height: 10),
                      _buildLanguageCard(state),
                      const SizedBox(height: 20),
                      _buildSectionLabel('STUDY TOPIC', Icons.menu_book_rounded),
                      const SizedBox(height: 10),
                      _buildTopicList(state),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      decoration: BoxDecoration(
        color: kColorSurface,
        border: Border(bottom: BorderSide(color: kColorBorder)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kColorPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 60,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kColorAccent.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: kColorPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Salearn',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: kColorText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'AI Language Tutor',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kColorTextMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Label ───────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kColorTextMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kColorTextMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: kColorBorder, thickness: 1, height: 1)),
      ],
    );
  }

  // ── API Key Card ────────────────────────────────────────────────────────────
  Widget _buildApiKeyCard(AppStateModel state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.vpn_key_rounded,
                    color: kColorPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: kColorAccent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: kColorText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste your key here...',
              fillColor: kColorBackground,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: _apiKeyController.clear,
                color: kColorTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Coral gradient button
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: kPrimaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: state.loadingPhase == LoadingPhase.testingKey
                    ? null
                    : () => _testAndSaveKey(state),
                child: Center(
                  child: state.loadingPhase == LoadingPhase.testingKey
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Test & Save',
                              style: TextStyle(
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
          ),
          const SizedBox(height: 8),
          // Ghost button
          OutlinedButton.icon(
            onPressed: _launchYouTube,
            icon: const Icon(Icons.play_circle_fill_rounded,
                color: kColorPrimary, size: 16),
            label: const Text(
              'How to get an API key',
              style: TextStyle(
                  color: kColorPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kColorPrimary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Card ───────────────────────────────────────────────────────────
  Widget _buildLanguageCard(AppStateModel state) {
    return Container(
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorBorder),
      ),
      child: Column(
        children: [
          _DropdownRow(
            label: 'I speak',
            value: state.nativeLanguage,
            items: kSupportedLanguages,
            onChanged: (val) { if (val != null) state.setNativeLanguage(val); },
          ),
          Divider(height: 1, color: kColorBorder),
          _DropdownRow(
            label: 'I want to learn',
            value: state.targetLanguage,
            items: kSupportedLanguages,
            onChanged: (val) { if (val != null) state.setTargetLanguage(val); },
          ),
        ],
      ),
    );
  }

  // ── Topic List ──────────────────────────────────────────────────────────────
  Widget _buildTopicList(AppStateModel state) {
    return Container(
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kTopics.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: kColorBorder),
        itemBuilder: (context, index) {
          final topic = kTopics[index];
          final isSelected = state.selectedTopic == topic;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              state.selectTopic(topic);
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? kColorPrimary.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? kColorPrimary : kColorAccent,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: kColorPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: kColorBorder),
        const SizedBox(height: 12),
        Text(
          'Salearn v1.0.0',
          style: TextStyle(
              color: kColorTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Powered by Abdelwahed Abdellaoui',
          style: TextStyle(color: kColorBorder, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Dropdown Row ──────────────────────────────────────────────────────────────
class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<Map<String, String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: kColorTextMuted, fontSize: 12)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down_rounded,
                color: kColorPrimary),
            dropdownColor: kColorSurface,
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(
                color: kColorAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            onChanged: onChanged,
            items: items.map((lang) {
              return DropdownMenuItem(
                value: lang['code'],
                child: Text(lang['label']!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}