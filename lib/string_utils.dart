import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

String sanitize(String s) {
  return s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int levenshtein(String a, String b) {
  final va = a.codeUnits;
  final vb = b.codeUnits;
  final m = va.length;
  final n = vb.length;
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (int i = 0; i <= m; i++) dp[i][0] = i;
  for (int j = 0; j <= n; j++) dp[0][j] = j;
  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      final cost = va[i - 1] == vb[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return dp[m][n];
}

int similarityPercent(String input, String target) {
  final a = sanitize(input);
  final b = sanitize(target);
  if (a == b) return 100;
  if (a.isEmpty || b.isEmpty) return 0;
  final dist = levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  return ((1 - dist / maxLen) * 100).round();
}

(Color color, IconData icon, String label) matchFeedback(int pct) {
  if (pct >= 85) {
    return (const Color(0xFF2ECC71), Icons.check_circle_rounded, 'correctFeedback'.tr());
  } else if (pct >= 50) {
    return (
      Colors.orange.shade700,
      Icons.warning_amber_rounded,
      'almostThere'.tr()
    );
  } else {
    return (const Color(0xFFE74C3C), Icons.cancel_rounded, 'tryAgain'.tr());
  }
}
