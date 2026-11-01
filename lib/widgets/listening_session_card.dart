import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'absorb_wave_icon.dart';

class ListeningSessionCard extends StatelessWidget {
  const ListeningSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  final Map<String, dynamic> session;
  final VoidCallback onTap;

  static final _idPattern = RegExp(
    r'^([a-z]{2,4}_)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final rawTitle = session['displayTitle'] as String?;
    final rawAuthor = session['displayAuthor'] as String?;
    final metadata = session['mediaMetadata'] as Map<String, dynamic>?;
    final title = rawTitle != null && !_idPattern.hasMatch(rawTitle)
        ? rawTitle
        : metadata?['title'] as String? ?? l.unknown;
    final author = rawAuthor != null && !_idPattern.hasMatch(rawAuthor)
        ? rawAuthor
        : metadata?['authorName'] as String? ?? '';
    final duration = session['timeListening'] is num
        ? (session['timeListening'] as num).toDouble()
        : 0.0;
    final updatedAt = session['updatedAt'] is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (session['updatedAt'] as num).toInt(),
          )
        : null;
    final deviceInfo =
        session['deviceInfo'] as Map<String, dynamic>? ?? const {};
    final clientName =
        deviceInfo['clientName'] as String? ??
        deviceInfo['deviceName'] as String? ??
        '';
    final isAbsorb = clientName.toLowerCase().contains('absorb');
    final isWear = isAbsorb && clientName.toLowerCase().contains('wear');
    final isReading = session['mediaPlayer'] == ApiService.readingMediaPlayer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isAbsorb ? Colors.tealAccent : cs.onSurfaceVariant)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: isReading
                        ? Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Colors.tealAccent.withValues(alpha: 0.9),
                          )
                        : isWear
                        ? AbsorbWatchIcon(
                            size: 20,
                            color: Colors.tealAccent.withValues(alpha: 0.9),
                          )
                        : isAbsorb
                        ? AbsorbWaveIcon(
                            size: 18,
                            color: Colors.tealAccent.withValues(alpha: 0.9),
                          )
                        : Icon(
                            _clientIcon(clientName),
                            size: 17,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (author.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDuration(duration, l),
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (updatedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _relativeDate(updatedAt, l),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _clientIcon(String clientName) {
    final lower = clientName.toLowerCase();
    if (lower.contains('audiobookshelf') || lower.contains('abs')) {
      return Icons.headphones_rounded;
    }
    if (lower.contains('web') || lower.contains('browser')) {
      return Icons.language_rounded;
    }
    if (lower.contains('ios') || lower.contains('apple')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('android')) return Icons.phone_android_rounded;
    if (lower.contains('sonos') || lower.contains('cast')) {
      return Icons.speaker_rounded;
    }
    return Icons.devices_rounded;
  }

  static String _formatDuration(double seconds, AppLocalizations l) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    if (hours > 0) return l.statsScreenDurationHm(hours, minutes);
    if (minutes > 0) return l.statsScreenDurationM(minutes);
    if (seconds > 0) return l.statsScreenDurationLessThanMin;
    return l.statsScreenDurationZero;
  }

  static String _relativeDate(DateTime date, AppLocalizations l) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return l.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l.daysAgo(difference.inDays);
    return '${date.month}/${date.day}';
  }
}
