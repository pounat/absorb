import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/wording.dart';
import '../utils/app_platform.dart';
import 'adaptive_modal.dart';

void showTipsSheet(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final l = AppLocalizations.of(context)!;
  final w = Wording.of(context);
  showAdaptiveSheetDialog(
    context: context, useSafeArea: true,
    backgroundColor: Colors.transparent,
    expand: false, initialChildSize: 0.75, minChildSize: 0.05, maxChildSize: 0.95,
    builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            )),
            Row(children: [
              Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 24),
              const SizedBox(width: 10),
              Text(l.tipsAndHiddenFeatures, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            _tipCard(cs, tt,
              icon: Icons.bookmark_added_rounded,
              title: l.tipsSheetQuickBookmarksTitle,
              desc: l.tipsSheetQuickBookmarksDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.touch_app_rounded,
              title: l.tipsSheetCoverPlayPauseTitle,
              desc: l.tipsSheetCoverPlayPauseDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.swipe_up_rounded,
              title: l.tipsSheetFullScreenPlayerTitle,
              desc: l.tipsSheetFullScreenPlayerDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.swipe_right_rounded,
              title: w.tipsSheetQuickAddAbsorbingTitle,
              desc: w.tipsSheetQuickAddAbsorbingDesc,
            ),
            if (!AppPlatform.isWeb)
              _tipCard(cs, tt,
                icon: Icons.vibration_rounded,
                title: l.tipsSheetShakeExtendSleepTitle,
                desc: l.tipsSheetShakeExtendSleepDesc,
              ),
            _tipCard(cs, tt,
              icon: Icons.auto_stories_rounded,
              title: l.tipsSheetSeriesNavigationTitle,
              desc: l.tipsSheetSeriesNavigationDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.swipe_rounded,
              title: l.tipsSheetSwipeBetweenBooksTitle,
              desc: l.tipsSheetSwipeBetweenBooksDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.touch_app_rounded,
              title: l.tipsSheetTapToSeekTitle,
              desc: l.tipsSheetTapToSeekDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.speed_rounded,
              title: l.tipsSheetSpeedAdjustedTimeTitle,
              desc: l.tipsSheetSpeedAdjustedTimeDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.history_rounded,
              title: l.tipsSheetPlaybackHistoryTitle,
              desc: l.tipsSheetPlaybackHistoryDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.replay_rounded,
              title: l.tipsSheetAutoRewindTitle,
              desc: l.tipsSheetAutoRewindDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.skip_next_rounded,
              title: l.tipsSheetSeriesQueueModeTitle,
              desc: l.tipsSheetSeriesQueueModeDesc,
            ),
            if (!AppPlatform.isWeb)
              _tipCard(cs, tt,
                icon: Icons.airplanemode_active_rounded,
                title: l.tipsSheetOfflineModeTitle,
                desc: l.tipsSheetOfflineModeDesc,
              ),
            _tipCard(cs, tt,
              icon: Icons.upcoming_rounded,
              title: l.tipsSheetUpcomingReleasesTitle,
              desc: l.tipsSheetUpcomingReleasesDesc,
            ),
            if (!AppPlatform.isWeb)
              _tipCard(cs, tt,
                icon: Icons.equalizer_rounded,
                title: l.tipsSheetPerBookEqTitle,
                desc: l.tipsSheetPerBookEqDesc,
              ),
            _tipCard(cs, tt,
              icon: Icons.speed_rounded,
              title: l.tipsSheetPerBookSpeedTitle,
              desc: l.tipsSheetPerBookSpeedDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.bedtime_rounded,
              title: l.tipsSheetAutoSleepWindowTitle,
              desc: l.tipsSheetAutoSleepWindowDesc,
            ),
            _tipCard(cs, tt,
              icon: Icons.notifications_active_rounded,
              title: l.tipsSheetSleepFadeChimeTitle,
              desc: l.tipsSheetSleepFadeChimeDesc,
            ),
            if (!AppPlatform.isWeb)
              _tipCard(cs, tt,
                icon: Icons.directions_car_rounded,
                title: l.tipsSheetCarModeTitle,
                desc: l.tipsSheetCarModeDesc,
              ),
            _tipCard(cs, tt,
              icon: Icons.search_rounded,
              title: l.tipsSheetAudibleSeriesTitle,
              desc: l.tipsSheetAudibleSeriesDesc,
            ),
          ],
        ),
      ),
  );
}

Widget _tipCard(ColorScheme cs, TextTheme tt, {required IconData icon, required String title, required String desc}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(desc, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            ],
          )),
        ],
      ),
    ),
  );
}
