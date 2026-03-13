import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) MobileAds.instance.initialize();
  runApp(const ProviderScope(child: ImaNoJishoApp()));
}

class ImaNoJishoApp extends StatelessWidget {
  const ImaNoJishoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '「今」の辞書',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
