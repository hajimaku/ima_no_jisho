import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final searchResultProvider =
    FutureProvider.family<SearchResult, String>((ref, word) async {
  final client = ref.read(apiClientProvider);
  return client.search(word);
});

final dailyWordProvider = FutureProvider<DailyWord>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.getDailyWord();
});

// 特定日付の一言（カレンダー・詳細画面用）
final dailyWordByDateProvider =
    FutureProvider.family<DailyWord, String?>((ref, date) async {
  final client = ref.read(apiClientProvider);
  return client.getDailyWord(date: date);
});
