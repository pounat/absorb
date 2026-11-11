import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Fork addition. One row shape for every episode list in the list layout -
// the Episodes feed, the Inbox and the queue - so they read as the same
// object wherever they turn up: cover, a quiet line of context, the title,
// then time. The only things that differ between lists are the leading drag
// handle and what the round button on the right does.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Nov 11", or "Nov 11 2025" once it's not this year.
String apShortDate(int epochMs) {
  if (epochMs <= 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final base = '${_months[d.month - 1]} ${d.day}';
  return d.year == DateTime.now().year ? base : '$base ${d.year}';
}

/// "3.1 MB" / "177 MB" / "1.2 GB".
String apFileSize(num bytes) {
  if (bytes <= 0) return '';
  final mb = bytes / (1024 * 1024);
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
  if (mb >= 10) return '${mb.round()} MB';
  return '${mb.toStringAsFixed(1)} MB';
}

/// "06:17" under an hour, "1:12:17" over. Negative input is clamped to zero.
String apClock(num seconds) {
  var s = seconds.isFinite ? seconds.round() : 0;
  if (s < 0) s = 0;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// "1h 12m" / "38m" / "under a minute" - for totals, where seconds are noise.
String apRoughDuration(num seconds) {
  final s = seconds.isFinite ? seconds.round() : 0;
  if (s < 60) return 'under a minute';
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  return '${m}m';
}

/// Square cover with a typographic fallback. Most of what lands in this
/// library has no art, or the same channel art fifty times over, so the
/// fallback is not an afterthought: a letter on a tint picked from the show's
/// name, which at least tells two shows apart at a glance.
class ApCover extends StatelessWidget {
  final String? url;
  final Map<String, String> headers;
  final String seed;
  final double size;
  final double radius;

  const ApCover({
    super.key,
    required this.url,
    required this.headers,
    required this.seed,
    this.size = 56,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tints = [
      (cs.primaryContainer, cs.onPrimaryContainer),
      (cs.secondaryContainer, cs.onSecondaryContainer),
      (cs.tertiaryContainer, cs.onTertiaryContainer),
      (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    ];
    final trimmed = seed.trim();
    var hash = 0;
    for (final unit in trimmed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final (bg, fg) = tints[hash % tints.length];
    final letter = trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();

    final fallback = Container(
      width: size,
      height: size,
      color: bg,
      alignment: Alignment.center,
      child: letter.isEmpty
          ? Icon(Icons.graphic_eq_rounded, size: size * 0.42, color: fg)
          : Text(
              letter,
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1,
              ),
            ),
    );

    final u = url;
    Widget image;
    if (u == null || u.isEmpty) {
      image = fallback;
    } else if (u.startsWith('/')) {
      // Downloaded items resolve to a local file path.
      image = Image.file(
        File(u),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: u,
        httpHeaders: headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// The round outlined button on the right of a row.
class ApRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;
  final double size;
  final String? tooltip;

  const ApRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.busy = false,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = filled ? cs.onPrimary : cs.onSurface;
    final button = Material(
      color: filled ? cs.primary : Colors.transparent,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(color: cs.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: busy
                ? SizedBox(
                    width: size * 0.42,
                    height: size * 0.42,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Icon(icon, size: size * 0.55, color: fg),
          ),
        ),
      ),
    );
    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

class ApEpisodeTile extends StatelessWidget {
  final String title;

  /// Show / author name. Leads the context line.
  final String context_;
  final String? coverUrl;
  final Map<String, String> coverHeaders;
  final int publishedAtMs;
  final num sizeBytes;
  final double durationSec;

  /// 0..1. Ignored when [positionSec] is given.
  final double progress;

  /// Live position for the item that is loaded in the player.
  final double? positionSec;
  final bool finished;
  final bool active;
  final bool downloaded;
  final Widget? leading;
  final Widget trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCoverTap;

  const ApEpisodeTile({
    super.key,
    required this.title,
    required String contextLine,
    required this.coverUrl,
    required this.coverHeaders,
    required this.durationSec,
    required this.trailing,
    this.publishedAtMs = 0,
    this.sizeBytes = 0,
    this.progress = 0,
    this.positionSec,
    this.finished = false,
    this.active = false,
    this.downloaded = false,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.onCoverTap,
  }) : context_ = contextLine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dim = cs.onSurfaceVariant;
    const tabular = [FontFeature.tabularFigures()];

    final pos = positionSec ??
        (progress > 0 && durationSec > 0 ? progress * durationSec : 0.0);
    final started = !finished && pos > 0 && durationSec > 0;
    final fraction =
        durationSec > 0 ? (pos / durationSec).clamp(0.0, 1.0).toDouble() : 0.0;

    final meta = [
      if (context_.isNotEmpty) context_,
      if (publishedAtMs > 0) apShortDate(publishedAtMs),
      if (sizeBytes > 0) apFileSize(sizeBytes),
    ].join(' · ');

    final metaStyle = tt.labelMedium?.copyWith(
      color: active ? cs.primary : dim,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final timeStyle = tt.labelMedium?.copyWith(
      color: dim,
      fontFeatures: tabular,
    );

    final cover = ApCover(
      url: coverUrl,
      headers: coverHeaders,
      seed: context_.isNotEmpty ? context_ : title,
    );

    return Material(
      color: active
          ? cs.primaryContainer.withValues(alpha: 0.28)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(leading == null ? 16 : 4, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) leading!,
              onCoverTap == null
                  ? cover
                  : GestureDetector(onTap: onCoverTap, child: cover),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (downloaded) ...[
                          Icon(Icons.download_done_rounded,
                              size: 14, color: active ? cs.primary : dim),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(
                        height: 1.2,
                        color: finished
                            ? cs.onSurface.withValues(alpha: 0.45)
                            : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (started)
                      Row(
                        children: [
                          Text(apClock(pos), style: timeStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 4,
                                backgroundColor: cs.surfaceContainerHighest,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('-${apClock(durationSec - pos)}',
                              style: timeStyle),
                        ],
                      )
                    else
                      Text(
                        finished
                            ? 'Played'
                            : (durationSec > 0 ? apClock(durationSec) : ''),
                        style: timeStyle,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
