import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/search/search_screen.dart';
import '../features/search/result_screen.dart';
import '../features/daily_word/daily_word_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/widgets/app_shell.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/daily-word',
          name: 'daily-word',
          builder: (context, state) => const DailyWordScreen(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    // ボトムナビの外（フルスクリーン遷移）
    GoRoute(
      path: '/result/:word',
      name: 'result',
      builder: (context, state) {
        final word = state.pathParameters['word'] ?? '';
        return ResultScreen(word: word);
      },
    ),
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('ページが見つかりません: ${state.error}')),
  ),
);
