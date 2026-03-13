import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'search_history';
  static const _max = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> _save(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list);
  }

  void add(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((w) => w != trimmed)]
        .take(_max)
        .toList();
    state = updated;
    _save(updated);
  }

  void remove(String word) {
    final updated = state.where((w) => w != word).toList();
    state = updated;
    _save(updated);
  }

  void clear() {
    state = [];
    _save([]);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

// 直前の検索結果の関連用語を保持する（ホーム画面に表示）
final lastRelatedWordsProvider = StateProvider<List<String>>((ref) => []);
