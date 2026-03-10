import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(
              color: AppColors.washi.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.vermillion.withOpacity(0.15),
          selectedIndex: currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppColors.vermillion),
              label: '検索',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: AppColors.vermillion),
              label: 'カレンダー',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.vermillion),
              label: '設定',
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
              case 1:
                context.go('/calendar');
              case 2:
                context.go('/settings');
            }
          },
        ),
      ),
    );
  }
}
