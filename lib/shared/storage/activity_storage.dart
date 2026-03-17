import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリのアクティビティをローカルに記録するストレージ
class ActivityStorage {
  static String _openedKey(int year, int month) => 'opened_${year}_$month';
  static String _viewedKey(int year, int month) => 'viewed_${year}_$month';
  static String _wordsKey(int year, int month) => 'words_${year}_$month';

  /// 今日を「アプリを開いた日」として記録
  static Future<void> recordOpen() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final key = _openedKey(now.year, now.month);
    final days = _loadIntSet(prefs, key);
    days.add(now.day);
    prefs.setString(key, jsonEncode(days.toList()));
  }

  /// 今日を「今日の一言を見た日」として記録
  static Future<void> recordDailyWordView() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final key = _viewedKey(now.year, now.month);
    final days = _loadIntSet(prefs, key);
    days.add(now.day);
    prefs.setString(key, jsonEncode(days.toList()));
  }

  /// 検索した単語を記録（今月分、重複なし、最大50語）
  static Future<void> recordSearch(String word) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final key = _wordsKey(now.year, now.month);
    final words = _loadStringList(prefs, key);
    if (!words.contains(word)) {
      words.insert(0, word);
      if (words.length > 50) words.removeLast();
      prefs.setString(key, jsonEncode(words));
    }
  }

  /// 指定月にアプリを開いた日のセットを返す
  static Future<Set<int>> getOpenedDays(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return _loadIntSet(prefs, _openedKey(year, month));
  }

  /// 指定月に今日の一言を見た日のセットを返す
  static Future<Set<int>> getViewedDays(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return _loadIntSet(prefs, _viewedKey(year, month));
  }

  /// 指定月に検索した単語リストを返す
  static Future<List<String>> getSearchedWords(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return _loadStringList(prefs, _wordsKey(year, month));
  }

  static Set<int> _loadIntSet(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).map((e) => e as int).toSet();
  }

  static List<String> _loadStringList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => e as String).toList();
  }
}
