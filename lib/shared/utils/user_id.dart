import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端末固有の匿名ユーザーID（UUIDv4風）を生成・永続化する
class UserId {
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('anonymous_user_id');
    if (id == null) {
      id = _generateId();
      await prefs.setString('anonymous_user_id', id);
    }
    _cached = id;
    return id;
  }

  static String _generateId() {
    // UUIDv4風の簡易生成
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = now ^ (now >> 16);
    return 'anon-$rand-${defaultTargetPlatform.name}';
  }
}
