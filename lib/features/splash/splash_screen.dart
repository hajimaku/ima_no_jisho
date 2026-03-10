import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opacity = _fadeIn.value * (1.0 - _fadeOut.value);
          return Opacity(
            opacity: opacity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 朱色の装飾ライン
                  Container(
                    width: 2,
                    height: 48,
                    color: AppColors.vermillion.withOpacity(0.6),
                  ),
                  const SizedBox(height: 24),
                  // アプリ名
                  Text(
                    '「今」の辞書',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.gold,
                          letterSpacing: 4,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '言葉の本来の意味と、今の使われ方を並べて見る',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.washi.withOpacity(0.45),
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 2,
                    height: 48,
                    color: AppColors.gold.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
