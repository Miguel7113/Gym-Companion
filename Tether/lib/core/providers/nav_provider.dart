import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// navIndexProvider — 4-tab layout (food feature shelved)
// ─────────────────────────────────────────────────────────────────────────────
abstract final class NavTab {
  static const int home = 0;
  static const int train = 1;
  static const int feed = 2;
  static const int profile = 3;
}

final navIndexProvider = StateProvider<int>((ref) => NavTab.home);
