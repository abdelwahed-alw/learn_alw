import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final TextEditingController _storyController = TextEditingController();
  final GeminiApiService _api = GeminiApiService();
  bool _loading = false;
  bool _submitting = false;
  WritingExercise? _exercise;
  WritingFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    // Listen for text changes so the Submit button reactivates when the
    // user types — fixes Task 3 (button was permanently disabled).
    _storyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _generateExercise() async {
    final state = context.read<AppStateModel>();
    if (!state.hasApiKey) {
      _showError('Please configure your API key first.');
      return;
    }
    setState(() {
      _loading = true;
      _exercise = null;
      _feedback = null;
      _storyController.clear();
    });
    try {
      final exercise = await _api.generateWritingExercise(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
      );
      if (mounted) {
        setState(() {
          _exercise = exercise;
          _loading = false;
        });
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _loading = false);
    }
  }

  Future<void> _submitStory() async {
    final story = _storyController.text.trim();
    if (story.isEmpty) return;

    final state = context.read<AppStateModel>();
    setState(() => _submitting = true);
    try {
      final feedback = await _api.evaluateWriting(
        apiKey: state.apiKey,
        targetLanguage: languageLabelFromCode(state.targetLanguage),
        nativeLanguage: languageLabelFromCode(state.nativeLanguage),
        topic: _exercise!.topic,
        story: story,
      );
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _submitting = false;
        });
        context.read<AppStateModel>().incrementCategoryProgress('writing');
      }
    } on GeminiServiceException catch (e) {
      if (mounted) _showError(e.message);
      setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kColorError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Writing Exercise',
          style: TextStyle(color: kColorText, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kColorText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_exercise != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Your Topic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _exercise!.topic,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _exercise!.instructions,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _storyController,
                maxLines: 10,
                minLines: 6,
                decoration: InputDecoration(
                  hintText:
                      'Write your story here in ${languageLabelFromCode(context.read<AppStateModel>().targetLanguage)}...',
                  filled: true,
                  fillColor: kColorSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedButton(
                isLoading: _submitting,
                label: 'Submit Story',
                onTap:
                    _storyController.text.trim().isEmpty ? null : _submitStory,
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kColorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 48,
                          color: kColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Creative Writing',
                        style: TextStyle(
                          color: kColorText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get a random topic and write a short story.\nSubmit to receive AI feedback.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kColorTextMuted.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _AnimatedButton(
                        isLoading: _loading,
                        label: 'Generate Topic',
                        onTap: _generateExercise,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kColorAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kColorAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: kColorAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Feedback',
                              style: TextStyle(
                                color: kColorAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _feedback!.feedback,
                          style: const TextStyle(
                            color: kColorText,
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                        if (_feedback!.suggestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Suggestions:',
                            style: TextStyle(
                              color: kColorText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._feedback!.suggestions.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    ' • ',
                                    style: TextStyle(color: kColorPrimary),
                                  ),
                                  Expanded(
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        color: kColorTextMuted.withValues(
                                            alpha: 0.8),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_feedback!.correctedVersion.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kColorSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Corrected Version:',
                                  style: TextStyle(
                                    color: kColorText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _feedback!.correctedVersion,
                                  style: TextStyle(
                                    color:
                                        kColorTextMuted.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _AnimatedButton(
                          isLoading: false,
                          label: 'Try New Topic',
                          onTap: _generateExercise,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onTap;

  const _AnimatedButton({
    required this.isLoading,
    required this.label,
    this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled ? kPrimaryGradient : null,
          color: enabled ? null : kColorSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: enabled ? Colors.white : kColorTextMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
