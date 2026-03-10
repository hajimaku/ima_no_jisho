import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';

// 設定状態
class _SettingsState {
  final String language; // 'ja' or 'en'
  final bool dailyNotification;

  const _SettingsState({
    this.language = 'ja',
    this.dailyNotification = false,
  });

  _SettingsState copyWith({String? language, bool? dailyNotification}) {
    return _SettingsState(
      language: language ?? this.language,
      dailyNotification: dailyNotification ?? this.dailyNotification,
    );
  }
}

final _settingsProvider =
    StateNotifierProvider<_SettingsNotifier, _SettingsState>(
  (ref) => _SettingsNotifier(),
);

class _SettingsNotifier extends StateNotifier<_SettingsState> {
  _SettingsNotifier() : super(const _SettingsState());

  void setLanguage(String lang) => state = state.copyWith(language: lang);
  void toggleNotification(bool val) =>
      state = state.copyWith(dailyNotification: val);
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(_settingsProvider);
    final notifier = ref.read(_settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // ─── 検索言語 ───
          _SectionHeader(label: '検索'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'デフォルト言語',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.washi.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _LangChip(
                      label: '日本語',
                      selected: settings.language == 'ja',
                      onTap: () => notifier.setLanguage('ja'),
                    ),
                    const SizedBox(width: 10),
                    _LangChip(
                      label: 'English',
                      selected: settings.language == 'en',
                      onTap: () => notifier.setLanguage('en'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Divider(),

          // ─── 通知 ───
          _SectionHeader(label: '通知'),
          _SettingsTile(
            title: '今日の一言（毎朝8時）',
            subtitle: '新しい言葉の雑学を毎朝お届け',
            trailing: Switch(
              value: settings.dailyNotification,
              onChanged: notifier.toggleNotification,
              activeColor: AppColors.vermillion,
              inactiveTrackColor: AppColors.card,
            ),
          ),
          _Divider(),

          // ─── このアプリについて ───
          _SectionHeader(label: 'このアプリについて'),
          _SettingsTile(
            title: 'バージョン',
            trailing: Text(
              '1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.washi.withOpacity(0.4),
              ),
            ),
          ),
          _SettingsTile(
            title: 'AI解析について',
            subtitle: '言葉の解析にClaude AIを使用しています',
          ),
          _SettingsTile(
            title: 'プライバシーポリシー',
            trailing: Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.washi.withOpacity(0.3),
            ),
          ),
          _Divider(),

          // ─── デザインについて ───
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✦ デザインコンセプト',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '墨・和紙・朱・金——日本の伝統色をダークテーマに昇華。'
                    '辞書的意味は藍色、今の使われ方は朱色で視覚的に分離しています。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.washi.withOpacity(0.55),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.gold.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.washi.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.vermillion.withOpacity(0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.vermillion.withOpacity(0.6)
                : AppColors.washi.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected
                    ? AppColors.vermillion
                    : AppColors.washi.withOpacity(0.5),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: AppColors.washi.withOpacity(0.06),
    );
  }
}
