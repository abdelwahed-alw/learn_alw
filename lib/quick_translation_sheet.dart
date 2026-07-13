import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'app_state_model.dart';
import 'constants.dart';
import 'gemini_api_service.dart';

void showQuickTranslationSheet(BuildContext context) {
  final state = context.read<AppStateModel>();
  final api = GeminiApiService();
  final inputController = TextEditingController();
  String translationText = '';
  String correctionText = '';
  bool loading = false;

  void _parseResponse(String response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response);
      final String rawTranslation = data['translation'] ?? '';
      final String rawCorrection = data['correction'] ?? '';
      translationText = rawTranslation.trim();
      correctionText = rawCorrection.isNotEmpty
          ? 'أنت تقصد: $rawCorrection'
          : '';
    } catch (_) {
      translationText = response;
      correctionText = '';
    }
  }

  final cs = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            Text(
                              'quickTranslation'.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.translate_rounded,
                                color: kColorPrimary),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: inputController,
                      maxLines: 3,
                      style: TextStyle(
                          color: cs.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'typeTextHere'.tr(),
                        hintStyle: TextStyle(
                          color: cs.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: loading
                          ? null
                          : () async {
                              final text =
                                  inputController.text.trim();
                              if (text.isEmpty) return;
                              setSheetState(() {
                                loading = true;
                                translationText = '';
                                correctionText = '';
                              });
                              try {
                                final response =
                                    await api.quickTranslate(
                                  apiKey: state.apiKey,
                                  inputText: text,
                                  nativeLanguage:
                                      languageLabelFromCode(
                                          state.nativeLanguage),
                                  targetLanguage:
                                      languageLabelFromCode(
                                          state.targetLanguage),
                                );
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    _parseResponse(response);
                                    loading = false;
                                  });
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  setSheetState(() {
                                    translationText =
                                        'translationFailed'.tr();
                                    correctionText = '';
                                    loading = false;
                                  });
                                }
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: kPrimaryGradient,
                          borderRadius:
                              BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kColorPrimary
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'translate'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (translationText.isNotEmpty ||
                        correctionText.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      if (correctionText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              correctionText,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          left: 14,
                          top: 14,
                          bottom: 14,
                          right: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection:
                                    TextDirection.ltr,
                                child: Text(
                                  translationText,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy,
                                  size: 20, color: Colors.grey),
                              onPressed: () {
                                if (translationText
                                    .isNotEmpty) {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: translationText
                                          .trim(),
                                    ),
                                  );
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'copied_successfully'
                                            .tr(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
