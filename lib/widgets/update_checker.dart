import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

// Drop into the home screen — checks once per app launch and shows the
// optional or force update dialog.
class UpdateChecker extends StatefulWidget {
  const UpdateChecker({super.key});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  static bool _checkedThisLaunch = false;
  final _service = AppUpdateService();

  @override
  void initState() {
    super.initState();
    if (_checkedThisLaunch) return;
    _checkedThisLaunch = true;
    _check();
  }

  Future<void> _check() async {
    final info = await _service.check();
    if (!mounted || info == null || info.type == UpdateType.none) return;
    final force = info.type == UpdateType.force;

    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(
                force ? Icons.system_update : Icons.new_releases_outlined,
                color: force ? AppColors.amber : AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(
                force ? 'Update required' : 'Update available',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                force
                    ? 'This version (${info.currentVersion}) is no longer supported. Please update to keep scoring.'
                    : 'PitchScore ${info.latestVersion} is available — you have ${info.currentVersion}.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (info.message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  info.message,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () {
                  _service.skip(info.latestVersion);
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Later',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ElevatedButton(
              onPressed: () => _openStore(info.storeUrl),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: Text(
                'Update now',
                style: TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
