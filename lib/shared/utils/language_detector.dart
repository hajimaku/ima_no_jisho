/// 入力文字列が英語か日本語かを判定するユーティリティ
class LanguageDetector {
  /// ASCII英字のみで構成されている場合は英語と判定
  static bool isEnglish(String text) {
    return RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(text.trim());
  }

  static String languageLabel(String text) {
    return isEnglish(text) ? '英語' : '日本語';
  }
}
