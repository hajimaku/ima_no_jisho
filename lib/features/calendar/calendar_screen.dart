import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../daily_word/daily_word_screen.dart';

// ダミーデータ：アプリを開いた日
final _openedDays = {3, 4, 5, 6, 7, 8, 9}; // 3月の日付
// ダミーデータ：今日の一言を見た日
final _viewedDailyWord = {7, 8, 9};
// ダミーデータ：今月調べた単語
final _searchedWords = ['確信犯', '煮詰まる', 'ヤバい', 'ら抜き言葉', '情けは人のためならず'];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DateTime _today = DateTime(2026, 3, 9);
  late DateTime _displayMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(_today.year, _today.month);
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (!next.isAfter(DateTime(_today.year, _today.month))) {
      setState(() {
        _displayMonth = next;
        _selectedDate = null;
      });
    }
  }

  bool get _isCurrentMonth =>
      _displayMonth.year == _today.year &&
      _displayMonth.month == _today.month;

  int get _streakDays => _openedDays.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ヘッダー
              Row(
                children: [
                  Text('カレンダー履歴', style: theme.textTheme.displayMedium),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.vermillion.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.vermillion.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$_streakDays日連続',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.vermillion,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // カレンダー本体
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 月切替
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: AppColors.washi),
                          onPressed: _prevMonth,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Spacer(),
                        Text(
                          '${_displayMonth.year}年${_displayMonth.month}月',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _isCurrentMonth
                                ? AppColors.washi.withOpacity(0.25)
                                : AppColors.washi,
                          ),
                          onPressed: _nextMonth,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 曜日ヘッダー
                    Row(
                      children: ['日', '月', '火', '水', '木', '金', '土']
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.washi.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),

                    // 日付グリッド
                    _buildCalendarGrid(context),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 選択日の一言プレビュー
              if (_selectedDate != null) _buildDayPreview(context),

              // 今月の統計
              _buildStats(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // 0=日曜

    final cells = <Widget>[];

    // 空白セル
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, day);
      final isToday = _isCurrentMonth && day == _today.day;
      final isOpened = _isCurrentMonth && _openedDays.contains(day);
      final isViewed = _isCurrentMonth && _viewedDailyWord.contains(day);
      final isFuture = date.isAfter(_today);
      final isSelected = _selectedDate?.day == day &&
          _selectedDate?.month == _displayMonth.month;

      cells.add(_CalendarCell(
        day: day,
        isToday: isToday,
        isOpened: isOpened,
        isViewed: isViewed,
        isFuture: isFuture,
        isSelected: isSelected,
        onTap: isFuture
            ? null
            : () => setState(() {
                  _selectedDate = date;
                }),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  Widget _buildDayPreview(BuildContext context) {
    final theme = Theme.of(context);
    final date = _selectedDate!;
    final dateStr = '${date.month}月${date.day}日';
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekday = weekdays[date.weekday % 7];

    // ダミーの一言タイトル
    final titles = {
      9: '「煮詰まる」の本当の意味',
      8: '「確信犯」は悪人じゃない？',
      7: '「情けは人のためならず」',
    };
    final title = titles[date.day] ?? 'この日の一言';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateStr（$weekday）の一言',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gold.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.pushNamed('daily-word'),
                child: Text(
                  '全文を読む →',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.vermillion,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今月の記録',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.washi.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                value: '${_searchedWords.length}語',
                label: '調べた言葉',
                color: AppColors.indigo,
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: '$_streakDays日',
                label: '連続記録',
                color: AppColors.vermillion,
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: '${_viewedDailyWord.length}回',
                label: '一言を閲覧',
                color: AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 今月調べた単語チップ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchedWords
                .map((word) => GestureDetector(
                      onTap: () => context
                          .pushNamed('result', pathParameters: {'word': word}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.washi.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          word,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.washi.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isOpened;
  final bool isViewed;
  final bool isFuture;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isOpened,
    required this.isViewed,
    required this.isFuture,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.vermillion.withOpacity(0.15)
              : isOpened
                  ? AppColors.vermillion.withOpacity(0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.vermillion.withOpacity(0.5))
              : isToday
                  ? Border.all(color: AppColors.washi.withOpacity(0.3))
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isFuture
                    ? AppColors.washi.withOpacity(0.2)
                    : isToday
                        ? AppColors.washi
                        : isOpened
                            ? AppColors.washi.withOpacity(0.9)
                            : AppColors.washi.withOpacity(0.4),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isOpened)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.vermillion,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isOpened && isViewed) const SizedBox(width: 2),
                if (isViewed)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.washi.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
