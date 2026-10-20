import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../bloc/history/match_history_bloc.dart';
import '../../bloc/history/match_history_event.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearHistory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear all history?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'All saved matches on this phone will be deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete all',
              style: TextStyle(color: AppColors.red),
            ),
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
          _tile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'Dark — easy on the eyes in the sun',
          ),
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
          const Center(
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
    Color color = AppColors.green,
    VoidCallback? onTap,
  }) {
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
