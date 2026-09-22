import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../build_info.dart';
import '../l10n/app_localizations.dart';
import '../services/update_checker_service.dart';
import 'overlay_toast.dart';
import 'wavy_progress_indicator.dart';

class UpdateDialog {
  /// Show the "Update available" prompt. Tapping Download performs an in-app
  /// download with a progress dialog, then launches the system installer.
  /// On any failure, falls back to launching the URL in the browser.
  static Future<void> show(BuildContext context, UpdateInfo info) async {
    final l = AppLocalizations.of(context)!;
    // "v1.9.3-240 (Beta 6)" / "1.9.3+237 (Beta 5)" during a beta cycle; the
    // remote number comes from the release notes, ours from this build.
    String withBeta(String version, int? beta) =>
        beta == null ? version : '$version (${l.betaLabel(beta)})';
    final latest = withBeta(info.latestVersion, info.latestBetaNumber);
    final current =
        withBeta(info.currentVersion, betaNumberFor(info.currentVersion));
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(info.isPreRelease ? l.preReleaseAvailable : l.updateAvailable),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.updateDialogContent(
              info.isPreRelease ? l.updateKindPreRelease : l.updateKindVersion,
              latest,
              current,
            )),
            if (info.packageLabel != null) ...[
              const SizedBox(height: 12),
              _UpdatePackageLabel(info.packageLabel!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              UpdateCheckerService.dismiss(info.latestVersion);
              Navigator.pop(ctx, false);
            },
            child: Text(l.later),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.downloadButton),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    await _runInstall(context, info);
  }

  static Future<void> _runInstall(BuildContext context, UpdateInfo info) async {
    final l = AppLocalizations.of(context)!;
    if (!info.isDirectApk) {
      await launchUrl(
        Uri.parse(info.downloadUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    final progress = ValueNotifier<double?>(null);

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.updateDownloading),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (_, p, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (info.packageLabel != null) ...[
                _UpdatePackageLabel(info.packageLabel!),
                const SizedBox(height: 12),
              ],
              WavyProgressIndicator(value: p),
              const SizedBox(height: 12),
              Text(
                p == null ? '...' : '${(p * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApkUpdater.cancel();
              Navigator.pop(ctx);
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    ));

    final result = await ApkUpdater.downloadAndInstall(
      info,
      onProgress: (received, total) {
        progress.value = total > 0 ? received / total : null;
      },
    );

    if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
    progress.dispose();
    if (!context.mounted) return;

    switch (result.status) {
      case ApkInstallStatus.ok:
      case ApkInstallStatus.cancelled:
        return;
      case ApkInstallStatus.permissionDenied:
        showOverlayToast(context, l.updateInstallPermissionDenied, icon: Icons.error_outline_rounded);
        return;
      case ApkInstallStatus.downloadFailed:
      case ApkInstallStatus.launchFailed:
        showOverlayToast(context, l.updateOpeningInBrowser, icon: Icons.open_in_browser_rounded);
        await launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdatePackageLabel extends StatelessWidget {
  final String label;

  const _UpdatePackageLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      );
}
