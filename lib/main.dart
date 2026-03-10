import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
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
