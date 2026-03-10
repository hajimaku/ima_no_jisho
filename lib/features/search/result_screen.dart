import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/api/api_client.dart';
import '../../shared/utils/language_detector.dart';
import '../../shared/utils/user_id.dart';
import 'search_result_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String word;

  const ResultScreen({super.key, required this.word});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerFadeIn() {
    if (!_hasAnimated) {
      _hasAnimated = true;
      _fadeController.forward();
      _sendSearchLog();
    }
  }

  Future<void> _sendSearchLog() async {
    try {
      final uid = await UserId.get();
      final client = ref.read(apiClientProvider);
      await client.logSearch(widget.word, uid);
    } catch (_) {
      // ログ失敗はサイレントに無視
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(searchResultProvider(widget.word));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: resultAsync.when(
          loading: () => _buildSkeleton(),
          error: (error, _) => _buildError(error),
          data: (result) {
            _triggerFadeIn();
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 180, height: 36),
        const SizedBox(height: 8),
        _SkeletonBox(width: 100, height: 18),
        const SizedBox(height: 8),
        Row(children: [
          _SkeletonBox(width: 48, height: 24),
          const SizedBox(width: 8),
          _SkeletonBox(width: 48, height: 24),
        ]),
        const SizedBox(height: 24),
        _SkeletonBlock(
            color: AppColors.dictBlock, borderColor: AppColors.indigo),
        const SizedBox(height: 16),
        _SkeletonBlock(
            color: AppColors.modernBlock, borderColor: AppColors.vermillion),
      ],
    );
  }

  Widget _buildError(Object error) {
    String message = 'エラーが発生しました';
    if (error is ApiException) {
      message = error.message;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.vermillion, size: 48),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(searchResultProvider(widget.word)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vermillion,
                foregroundColor: AppColors.washi,
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordHeader(
          word: widget.word,
          reading: result.reading,
          pos: result.pos,
        ),
        const SizedBox(height: 24),
        _MeaningBlock(
          label: '📖 辞書的意味',
          labelColor: AppColors.indigo,
          blockColor: AppColors.dictBlock,
          content: result.dictMeaning,
          example: result.dictExample,
          isAI: false,
          source: 'AI解析',
        ),
        const SizedBox(height: 16),
        _MeaningBlock(
          label: '🔥 今の使われ方',
          labelColor: AppColors.vermillion,
          blockColor: AppColors.modernBlock,
          content: result.modernMeaning,
          example: result.modernExample,
          isAI: true,
          source: null,
        ),
        if (result.caution != null) ...[
          const SizedBox(height: 16),
          _CautionBlock(
            caution: result.caution,
            usageRatio: result.usageRatio,
          ),
        ],
      ],
    );
  }
}

// 単語ヘッダー
class _WordHeader extends StatelessWidget {
  final String word;
  final String reading;
  final String pos;

  const _WordHeader({
    required this.word,
    required this.reading,
    required this.pos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(word, style: theme.textTheme.displayLarge),
        const SizedBox(height: 6),
        Text(
          reading,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.washi.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Badge(label: pos, color: AppColors.indigo),
            const SizedBox(width: 6),
            _Badge(
              label: LanguageDetector.languageLabel(word),
              color: AppColors.washi.withOpacity(0.2),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.washi.withOpacity(0.8),
              fontSize: 11,
            ),
      ),
    );
  }
}

// スケルトンUI
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

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

class _SkeletonBlock extends StatelessWidget {
  final Color color;
  final Color borderColor;

  const _SkeletonBlock({required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 80, height: 20),
          const SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _SkeletonBox(width: 200, height: 14),
          const SizedBox(height: 12),
          _SkeletonBox(width: 160, height: 12),
        ],
      ),
    );
  }
}

// 意味ブロック
class _MeaningBlock extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color blockColor;
  final String content;
  final String example;
  final bool isAI;
  final String? source;

  const _MeaningBlock({
    required this.label,
    required this.labelColor,
    required this.blockColor,
    required this.content,
    required this.example,
    required this.isAI,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: labelColor.withOpacity(0.3), width: 1),
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
                  color: labelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isAI) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.vermillion.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppColors.vermillion.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '[AI解析]',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.vermillion.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              if (source != null) ...[
                const Spacer(),
                Text(
                  source!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.washi.withOpacity(0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: theme.textTheme.bodyLarge),
          if (example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '例）$example',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.washi.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 誤用注意ブロック
class _CautionBlock extends StatelessWidget {
  final String? caution;
  final String? usageRatio;

  const _CautionBlock({required this.caution, required this.usageRatio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (caution == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                '誤用注意',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (usageRatio != null) ...[
                const Spacer(),
                Text(
                  usageRatio!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gold.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caution!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.washi.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
