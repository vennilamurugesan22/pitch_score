import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../bloc/history/match_history_bloc.dart';
import '../../bloc/history/match_history_event.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearHistory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear all history?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'All saved matches on this phone will be deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete all', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<MatchHistoryBloc>().add(const ClearHistoryEvent());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('History cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ThemePicker(),
          _tile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear match history',
            subtitle: 'Delete all saved matches',
            color: AppColors.red,
            onTap: () => _clearHistory(context),
          ),
          const SizedBox(height: 20),
          _tile(
            icon: Icons.info_outline,
            title: 'About PitchScore',
            subtitle:
                'Ball-by-ball scorer for gully, box and office cricket. Works offline; '
                'turn on Live Sharing to let friends follow on their phones.',
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => _tile(
              icon: Icons.verified_outlined,
              title: 'Version',
              subtitle: snap.hasData
                  ? '${snap.data!.version} (build ${snap.data!.buildNumber})'
                  : '…',
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Score · Share · Celebrate',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    VoidCallback? onTap,
  }) {
    color ??= AppColors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

// Dark / Light / System — dark is the default
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  static const _options = [
    (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
    (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
    (ThemeMode.system, Icons.brightness_auto_outlined, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: AppColors.green),
                const SizedBox(width: 16),
                Text(
                  'Theme',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                switch (mode) {
                  ThemeMode.dark => 'Easy on the eyes, saves battery',
                  ThemeMode.light => 'Bright and clear for day matches',
                  ThemeMode.system => 'Follows your phone setting',
                },
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (value, icon, label) in _options)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _option(
                        icon: icon,
                        label: label,
                        selected: mode == value,
                        onTap: () => controller.setMode(value),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDark : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.green : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.green : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
