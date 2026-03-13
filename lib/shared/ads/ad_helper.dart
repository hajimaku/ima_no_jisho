import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) return 'ca-app-pub-1539238100617588/8635065961';
    return 'ca-app-pub-1539238100617588/1625611547';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) return 'ca-app-pub-1539238100617588/8838245949';
    return 'ca-app-pub-1539238100617588/9312529874';
  }
}
