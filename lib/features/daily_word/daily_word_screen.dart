import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/api/api_client.dart';
import '../../shared/utils/user_id.dart';
import '../search/search_result_provider.dart';

class DailyWordScreen extends ConsumerStatefulWidget {
  final DateTime? date;

  const DailyWordScreen({super.key, this.date});

  @override
  ConsumerState<DailyWordScreen> createState() => _DailyWordScreenState();
}

class _DailyWordScreenState extends ConsumerState<DailyWordScreen> {
  late DateTime _currentDate;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date ?? _today;
  }

  String get _dateKey =>
      '${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.day.toString().padLeft(2, '0')}';

  bool get _isToday =>
      _currentDate.year == _today.year &&
      _currentDate.month == _today.month &&
      _currentDate.day == _today.day;

  bool get _isFuture => _currentDate.isAfter(_today);

  Future<void> _sendDailyWordLog() async {
    try {
      final uid = await UserId.get();
      final client = ref.read(apiClientProvider);
      await client.logDailyWord(_dateKey, uid);
    } catch (_) {
      // ログ失敗はサイレントに無視
    }
  }

  void _goToPrev() {
    setState(() => _currentDate = _currentDate.subtract(const Duration(days: 1)));
  }

  void _goToNext() {
    if (!_isFuture) {
      setState(() => _currentDate = _currentDate.add(const Duration(days: 1)));
    }
  }

  void _share(BuildContext context, DailyWord data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShareSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 今日は dailyWordProvider（キャッシュ効率化）、それ以外は日付指定
    final dailyAsync = _isToday
        ? ref.watch(dailyWordProvider)
        : ref.watch(dailyWordByDateProvider(_dateKey));

    final dateStr =
        '${_currentDate.year}年${_currentDate.month}月${_currentDate.day}日';
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekday = weekdays[_currentDate.weekday % 7];

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の一言'),
        actions: [
          dailyAsync.whenOrNull(
            data: (data) => IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _share(context, data),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付ヘッダー
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '✦ 今日の一言',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$dateStr（$weekday）',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.washi.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            dailyAsync.when(
              loading: () => _buildSkeleton(theme),
              error: (e, _) => Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.error_outline,
                        color: AppColors.vermillion, size: 40),
                    const SizedBox(height: 12),
                    Text('取得に失敗しました',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_isToday) {
                          ref.invalidate(dailyWordProvider);
                        } else {
                          ref.invalidate(dailyWordByDateProvider(_dateKey));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vermillion,
                        foregroundColor: AppColors.washi,
                      ),
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                _sendDailyWordLog();
                return _buildContent(context, theme, data);
              },
            ),

            const SizedBox(height: 32),

            // 前後ナビ
            Row(
              children: [
                _NavButton(
                  label: '← 前の日',
                  onTap: _goToPrev,
                  enabled: true,
                ),
                const Spacer(),
                _NavButton(
                  label: '次の日 →',
                  onTap: _goToNext,
                  enabled: !_isFuture,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Skeleton(width: 240, height: 28),
        const SizedBox(height: 8),
        _Skeleton(width: 160, height: 22),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Skeleton(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              _Skeleton(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              _Skeleton(width: 200, height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, ThemeData theme, DailyWord data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppColors.gold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // 本文
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.gold, width: 3),
            ),
          ),
          child: Text(
            data.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.8,
              color: AppColors.washi.withOpacity(0.9),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 言葉カードプレビュー（シェア用）
        _WordCard(data: data),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'タップしてシェア',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.gold.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (data.relatedWords.isNotEmpty) ...[
          Text(
            '関連して調べる',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.washi.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.relatedWords.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final word = data.relatedWords[i];
                return GestureDetector(
                  onTap: () => context.pushNamed('result',
                      pathParameters: {'word': word}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      word,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gold.withOpacity(0.8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// シェア用言葉カード（画面内プレビューも兼ねる）
class _WordCard extends StatelessWidget {
  final DailyWord data;

  const _WordCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.card,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => _ShareSheet(data: data),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ラベル
            Row(
              children: [
                Text(
                  '✦ 今日の一言',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gold.withOpacity(0.7),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Icon(Icons.share_outlined,
                    color: AppColors.gold.withOpacity(0.5), size: 16),
              ],
            ),
            const SizedBox(height: 12),
            // タイトル
            Text(
              data.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.gold,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // 本文（2行まで）
            Text(
              data.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.washi.withOpacity(0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            // フッター
            Text(
              '「今」の辞書',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gold.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;

  const _Skeleton({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppColors.washi.withOpacity(0.2)
                : AppColors.washi.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled
                    ? AppColors.washi.withOpacity(0.7)
                    : AppColors.washi.withOpacity(0.25),
              ),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final DailyWord data;

  const _ShareSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareText =
        '【今日の一言】\n${data.title}\n\n${data.body}\n\n#今の辞書 #言葉の雑学';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('シェア', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // カードプレビュー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✦ 今日の一言',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gold.withOpacity(0.6),
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.washi.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '「今」の辞書',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gold.withOpacity(0.35),
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _ShareOption(
            icon: Icons.copy,
            label: 'テキストをコピー',
            onTap: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('コピーしました')),
              );
            },
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.share,
            label: 'X（Twitter）でシェア',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.chat_bubble_outline,
            label: 'LINEでシェア',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.washi.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.washi.withOpacity(0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
