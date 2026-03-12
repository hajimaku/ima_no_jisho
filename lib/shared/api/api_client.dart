import 'dart:convert';
import 'package:http/http.dart' as http;

// ローカル開発: flutter run --dart-define=API_BASE_URL=http://localhost:8000
// 本番: デフォルトでRenderのURLを使用
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://ima-no-jisho.onrender.com',
);

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class SearchResult {
  final String word;
  final String reading;
  final String pos;
  final String dictMeaning;
  final String dictExample;
  final String modernMeaning;
  final String modernExample;
  final String? caution;
  final String? usageRatio;
  final List<String> relatedWords;

  const SearchResult({
    required this.word,
    required this.reading,
    required this.pos,
    required this.dictMeaning,
    required this.dictExample,
    required this.modernMeaning,
    required this.modernExample,
    this.caution,
    this.usageRatio,
    this.relatedWords = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      word: json['word'] as String,
      reading: json['reading'] as String,
      pos: json['pos'] as String,
      dictMeaning: json['dict_meaning'] as String,
      dictExample: json['dict_example'] as String,
      modernMeaning: json['modern_meaning'] as String,
      modernExample: json['modern_example'] as String,
      caution: json['caution'] as String?,
      usageRatio: json['usage_ratio'] as String?,
      relatedWords: List<String>.from(json['related_words'] as List? ?? []),
    );
  }
}

class DailyWord {
  final String date;
  final String title;
  final String body;
  final List<String> relatedWords;

  const DailyWord({
    required this.date,
    required this.title,
    required this.body,
    required this.relatedWords,
  });

  factory DailyWord.fromJson(Map<String, dynamic> json) {
    return DailyWord(
      date: json['date'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedWords: List<String>.from(json['related_words'] as List? ?? []),
    );
  }
}

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? apiBaseUrl;

  Future<SearchResult> search(String word) async {
    final uri = Uri.parse('$baseUrl/api/search');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return SearchResult.fromJson(json);
    }

    final error = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(
      response.statusCode,
      error['detail'] as String? ?? '検索に失敗しました',
    );
  }

  Future<void> logSearch(String word, String userId) async {
    final uri = Uri.parse('$baseUrl/api/log/search');
    await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word, 'user_id': userId}),
        )
        .timeout(const Duration(seconds: 5));
    // ログ失敗はサイレントに無視（ユーザー体験を損なわない）
  }

  Future<void> logDailyWord(String date, String userId) async {
    final uri = Uri.parse('$baseUrl/api/log/daily-word');
    await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'date': date, 'user_id': userId}),
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<DailyWord> getDailyWord({String? date}) async {
    final path = date != null ? '/api/daily-word/$date' : '/api/daily-word';
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return DailyWord.fromJson(json);
    }

    final error = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(
      response.statusCode,
      error['detail'] as String? ?? '今日の一言の取得に失敗しました',
    );
  }
}
