// lib/drawer_widget.dart
// Premium UI Sidebar for configuration (API key, languages, topics).

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
    // Pre-fill the text field with the saved API key.
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
            backgroundColor: kColorAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: kColorError,
          ),
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
      child: Consumer<AppStateModel>(
        builder: (context, state, child) {
          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient.scale(0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language_rounded,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Salearn',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI Language Tutor',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ──────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildApiKeySection(context, state),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                          context, 'Languages', Icons.translate_rounded),
                      const SizedBox(height: 16),
                      _buildLanguageDropdowns(state),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                          context, 'Study Topic', Icons.menu_book_rounded),
                      const SizedBox(height: 16),
                      _buildTopicList(state),
                      const SizedBox(height: 40),
                      _buildAboutSection(context),
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

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kColorTextMuted),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: kColorTextMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  // ── 1. API Key Section ──────────────────────────────────────────────────────
  Widget _buildApiKeySection(BuildContext context, AppStateModel state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 4, 8, 15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Color.fromARGB(255, 0, 0, 0), size: 20),
              const SizedBox(width: 8),
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Paste your key here...',
              fillColor: kColorSurface,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _apiKeyController.clear,
                color: kColorTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: state.loadingPhase == LoadingPhase.testingKey
                ? null
                : () => _testAndSaveKey(state),
            icon: state.loadingPhase == LoadingPhase.testingKey
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              state.loadingPhase == LoadingPhase.testingKey
                  ? 'Verifying...'
                  : 'Test & Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _launchYouTube,
            icon: const Icon(Icons.play_circle_fill_rounded,
                color: kColorSecondary, size: 20),
            label: const Text(
              'How to get an API key',
              style: TextStyle(
                  color: kColorSecondary, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Language Pickers ─────────────────────────────────────────────────────
  Widget _buildLanguageDropdowns(AppStateModel state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder),
      ),
      child: Column(
        children: [
          _DropdownRow(
            label: 'I speak',
            value: state.nativeLanguage,
            items: kSupportedLanguages,
            onChanged: (val) {
              if (val != null) state.setNativeLanguage(val);
            },
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'I want to learn',
            value: state.targetLanguage,
            items: kSupportedLanguages,
            onChanged: (val) {
              if (val != null) state.setTargetLanguage(val);
            },
          ),
        ],
      ),
    );
  }

  // ── 3. Topic List ───────────────────────────────────────────────────────────
  Widget _buildTopicList(AppStateModel state) {
    return Container(
      decoration: BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kTopics.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final topic = kTopics[index];
          final isSelected = state.selectedTopic == topic;

          return ListTile(
            title: Text(
              topic,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? kColorPrimary : kColorText,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: kColorPrimary)
                : null,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              state.selectTopic(topic);
              // Close the drawer if on mobile.
              if (Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }

  // ── 4. About Section ────────────────────────────────────────────────────────
  Widget _buildAboutSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Salearn v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kColorTextMuted,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Powered by bdelwahed Abdellaoui',
            style: TextStyle(color: kColorTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable custom styled dropdown row ──────────────────────────────────────
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
          Text(
            label,
            style: const TextStyle(color: kColorTextMuted, fontSize: 14),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon:
                const Icon(Icons.arrow_drop_down_rounded, color: kColorPrimary),
            dropdownColor: kColorSurface,
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(
              color: kColorText,
              fontSize: 16,
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
        ],
      ),
    );
  }
}
