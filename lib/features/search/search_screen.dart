import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../app/theme.dart';
import '../../shared/ads/ad_helper.dart';
import 'search_provider.dart';
import 'search_result_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  InterstitialAd? _interstitialAd;
  int _searchCount = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _search([String? word]) {
    final query = (word ?? _controller.text).trim();
    if (query.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).add(query);
    _controller.clear();

    _searchCount++;
    if (!kIsWeb && _searchCount % 5 == 0 && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
          context.pushNamed('result', pathParameters: {'word': query});
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _loadInterstitial();
          context.pushNamed('result', pathParameters: {'word': query});
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      context.pushNamed('result', pathParameters: {'word': query});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(searchHistoryProvider);
    final relatedWords = ref.watch(lastRelatedWordsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('「今」の辞書', style: theme.textTheme.displayLarge),
              const SizedBox(height: 4),
              Text(
                '言葉の本来の意味と、今の使われ方を並べて見る',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.washi.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),

              // 検索バー
              TextField(
                controller: _controller,
                style: theme.textTheme.bodyLarge,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: '言葉を調べる...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.washi),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward,
                        color: AppColors.vermillion),
                    onPressed: () => _search(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 今日の一言カード
              _DailyWordCard(),
              const SizedBox(height: 24),

              // 関連して調べる
              if (relatedWords.isNotEmpty) ...[
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
                    itemCount: relatedWords.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final word = relatedWords[index];
                      return _SearchChip(
                        label: word,
                        onTap: () => _search(word),
                        onLongPress: () {},
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 最近の検索
              if (history.isNotEmpty) ...[
                Text(
                  '最近調べた言葉',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.washi.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final word = history[index];
                      return _SearchChip(
                        label: word,
                        onTap: () => _search(word),
                        onLongPress: () => _showDeleteDialog(context, word),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String word) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('削除', style: Theme.of(context).textTheme.headlineMedium),
        content: Text('「$word」を検索履歴から削除しますか？',
            style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('キャンセル',
                style: TextStyle(color: AppColors.washi.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              ref.read(searchHistoryProvider.notifier).remove(word);
              Navigator.pop(ctx);
            },
            child: const Text('削除',
                style: TextStyle(color: AppColors.vermillion)),
          ),
        ],
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SearchChip({
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.vermillion.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.washi.withOpacity(0.8),
              ),
        ),
      ),
    );
  }
}

class _DailyWordCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyAsync = ref.watch(dailyWordProvider);

    return GestureDetector(
      onTap: () => context.pushNamed('daily-word'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: AppColors.gold, width: 4),
            left: BorderSide(color: AppColors.gold.withOpacity(0.15), width: 1),
            right:
                BorderSide(color: AppColors.gold.withOpacity(0.15), width: 1),
            bottom:
                BorderSide(color: AppColors.gold.withOpacity(0.15), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Icon(Icons.chevron_right,
                    color: AppColors.gold.withOpacity(0.6), size: 18),
              ],
            ),
            const SizedBox(height: 12),
            dailyAsync.when(
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              error: (_, __) => Text(
                '「煮詰まる」の本当の意味',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.gold,
                ),
              ),
              data: (daily) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daily.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    daily.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.washi.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '詳しく見る →',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gold.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
