import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const int _maxHistory = 10;

  @override
  List<String> build() => [];

  void add(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((w) => w != trimmed)];
    state = updated.take(_maxHistory).toList();
  }

  void remove(String word) {
    state = state.where((w) => w != word).toList();
  }

  void clear() {
    state = [];
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
