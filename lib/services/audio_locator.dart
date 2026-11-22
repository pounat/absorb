import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'audio_player_service.dart';
import 'find_in_ebook.dart';
import 'sync_point_store.dart';
import 'transcription_service.dart';
import '../utils/chapter_title_match.dart';

/// What Find in audiobook needs from a book's text: the reader's open pages,
/// or the EPUB file read with no reader open.
abstract class BookTextSource {
  Future<List<String>> spineHrefs();
  String? chapterForHref(String href);
  Future<List<double>> sectionCharCounts(int from, int to);

  /// {s, e, fine} for where [transcript] sits in section [si]'s text.
  Future<Map<String, dynamic>?> locateTranscriptInSection(int si, String transcript);
}

/// Find in audiobook: where a spot in the ebook is in the audio. Anchors on
/// sync points or the matching audio chapter, then transcribes short probes
/// and matches them back into the section's text until one covers the spot.
class AudioLocator {
  AudioLocator(this.itemId, this.text);

  final String itemId;
  final BookTextSource text;

  // Find in audiobook: how much audio each probe transcribes, how many
  // estimate-correct-retry rounds the main anchor gets, and the ceiling once
  // the fallback candidates (player position, book percentage, neighbouring
  // chapters) have taken two rounds each. A probe is roughly ten seconds.
  static const double _probeWindowSeconds = 30.0;
  static const int _maxProbes = 5;
  static const int _maxTotalProbes = 12;
  // Narration pace measured on real books: ~0.07-0.08 s per character. Used
  // when no audio chapter anchors the estimate, and to reject absurd
  // chapter-derived rates (3-second "chapters" exist in the wild).
  static const double _fallbackSecPerChar = 0.075;
  // How far a failed probe shifts the search around the original estimate,
  // at minimum; a long section widens it so the probes spread across it.
  static const double _scanStepSeconds = 90.0;

  /// Where the audiobook should be for the spot in [info] (si, offset,
  /// total, href) and the range it could sit in, from sync points or a
  /// uniquely named audio chapter. Nothing is transcribed.
  Future<({double est, double lo, double hi})?> estimate(Map<String, dynamic> info, ApiService? api) async {
    final si = (info['si'] as num).toInt();
    final offset = (info['offset'] as num).toDouble();
    final total = (info['total'] as num).toDouble();
    if (total <= 0 || offset < 0) return null;
    final audio = await resolveAudioChapters(itemId, api);
    if (audio.duration <= 0) return null;
    final spine = await text.spineHrefs();
    await SyncPointStore.instance.load(
      itemId,
      audioDuration: audio.duration,
      spineLength: spine.isEmpty ? null : spine.length,
    );
    final sync = await _syncPointCandidate(
        si: si,
        offset: offset,
        total: total,
        fallbackRate: _fallbackSecPerChar,
        top: audio.duration);
    if (sync != null) return (est: sync.est, lo: sync.lo, hi: sync.hi);
    // A title that several audio chapters share can't place the page.
    final tocTitle = text.chapterForHref(info['href'] as String? ?? '');
    final named = [
      for (final ch in audio.chapters)
        if (ch is Map<String, dynamic> &&
            chapterTitlesAgree(ch['title'] as String?, tocTitle))
          ch,
    ];
    if (named.length != 1) return null;
    final a =
        _chapterAnchorEstimate(named.first, offset, total, audio.duration);
    return (est: a.est, lo: a.lo, hi: a.hi);
  }

  /// The time in the audiobook for the spot in [info] (si, offset, total,
  /// href, and pct when known), or null when no probe matched it.
  Future<double?> locate(Map<String, dynamic> info, ApiService? api) async {
    final si = (info['si'] as num).toInt();
    final offset = (info['offset'] as num).toDouble();
    final total = (info['total'] as num).toDouble();
    final href = info['href'] as String? ?? '';
    if (total <= 0 || offset < 0) return null;

    final audio = await resolveAudioChapters(itemId, api);
    if (audio.chapters.isEmpty) {
      debugPrint('[FindAudio] no audio chapters');
      return null;
    }
    final spineAll = await text.spineHrefs();
    await SyncPointStore.instance.load(
      itemId,
      audioDuration: audio.duration > 0 ? audio.duration : null,
      spineLength: spineAll.isEmpty ? null : spineAll.length,
    );
    Future<double> remember(double t) async {
      await SyncPointStore.instance.add(
        itemId,
        SyncPoint(t: t, si: si, off: offset, src: 'a'),
      );
      return t;
    }

    // Which audio chapter is this section? That anchors both the initial
    // estimate and the seconds-per-character correction rate. Books whose
    // chapters are plain names (alternating POV) repeat titles, so collect
    // every agreeing audio chapter and pick by occurrence - the 3rd "Sydney"
    // section anchors on the 3rd "Sydney" audio chapter. When the counts
    // don't line up, take the one nearest the selection's position in the
    // book, and keep a runner-up to probe if the first anchor turns out wrong.
    final tocTitle = text.chapterForHref(href);
    final bookEnd = audio.duration > 0 ? audio.duration : double.infinity;
    final pct = (info['pct'] as num?)?.toDouble();
    final agreeing = <Map<String, dynamic>>[];
    for (final ch in audio.chapters) {
      final m = ch as Map<String, dynamic>;
      if (chapterTitlesAgree(m['title'] as String?, tocTitle)) agreeing.add(m);
    }
    Map<String, dynamic>? audioCh;
    Map<String, dynamic>? audioChAlt;
    if (agreeing.length == 1) {
      audioCh = agreeing.first;
    } else if (agreeing.length > 1) {
      // Occurrence counting walks the spine and counts transitions into the
      // title, so a chapter split across several files still counts once and
      // two same-named chapters separated by an unnamed split file count
      // twice.
      final hrefs = await text.spineHrefs();
      var occurrence = 0;
      String? prev;
      for (var i = 0; i <= si && i < hrefs.length; i++) {
        final t = text.chapterForHref(hrefs[i]);
        if (t == tocTitle && prev != tocTitle) occurrence++;
        prev = t;
      }
      final targetFrac = (pct != null && pct > 0)
          ? pct
          : (hrefs.isNotEmpty ? si / hrefs.length : 0.5);
      double fracOf(Map<String, dynamic> m) {
        final s = (m['start'] as num?)?.toDouble() ?? 0;
        final e = (m['end'] as num?)?.toDouble() ?? s;
        return audio.duration > 0 ? ((s + e) / 2) / audio.duration : 0;
      }
      final byFrac = List<Map<String, dynamic>>.from(agreeing)
        ..sort((x, y) => (fracOf(x) - targetFrac)
            .abs()
            .compareTo((fracOf(y) - targetFrac).abs()));
      final picked = (occurrence >= 1 && occurrence <= agreeing.length)
          ? agreeing[occurrence - 1]
          : byFrac.first;
      audioCh = picked;
      for (final m in byFrac) {
        if (!identical(m, picked)) {
          audioChAlt = m;
          break;
        }
      }
      debugPrint('[FindAudio] "$tocTitle" matches ${agreeing.length} audio '
          'chapters, occurrence #$occurrence -> '
          '"${picked['title']}"@${((picked['start'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}s'
          '${audioChAlt != null ? ', runner-up @${((audioChAlt['start'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}s' : ''}');
    }

    double lo, hi, rate;
    double est;
    var anchorRate = double.nan;
    if (audioCh != null) {
      final a = _chapterAnchorEstimate(audioCh, offset, total, bookEnd);
      lo = a.lo;
      hi = a.hi;
      rate = a.rate;
      est = a.est;
      final chStart = (audioCh['start'] as num?)?.toDouble() ?? 0;
      final chEnd = (audioCh['end'] as num?)?.toDouble() ?? bookEnd;
      anchorRate = (chEnd - chStart) / total;
      if (anchorRate > 0.2 && chEnd.isFinite) {
        // One audio chapter covering several ebook sections (a whole part
        // with no chapter markers): pace through the text of the sections
        // before this one under the same TOC entry, and take the rate from
        // the run as a whole rather than this section alone.
        final hrefs = await text.spineHrefs();
        var first = si;
        while (first > 0 &&
            first > si - 12 &&
            first - 1 < hrefs.length &&
            text.chapterForHref(hrefs[first - 1]) == tocTitle) {
          first--;
        }
        var last = si;
        while (last + 1 < hrefs.length &&
            last < si + 12 &&
            (text.chapterForHref(hrefs[last + 1]) ?? tocTitle) == tocTitle) {
          last++;
        }
        final counts = await text.sectionCharCounts(first, last);
        if (counts.length == last - first + 1) {
          double before = 0, run = 0;
          for (var i = 0; i < counts.length; i++) {
            final n = first + i == si ? total : counts[i];
            run += n;
            if (first + i < si) before += n;
          }
          final runRate = run > 0 ? (chEnd - chStart) / run : double.nan;
          rate = (runRate >= 0.03 && runRate <= 0.2)
              ? runRate
              : _fallbackSecPerChar;
          est = (chStart + (before + offset) * rate).clamp(chStart, chEnd);
          lo = chStart;
          hi = chEnd;
          debugPrint('[FindAudio] anchor spans sections $first-$last '
              '(${run.toInt()} chars, ${before.toInt()} before this one) '
              'rate=${rate.toStringAsFixed(4)} est=${est.toStringAsFixed(1)}');
        }
      }
      // A marker that sits a little late (the part's interlude narrated under
      // the previous chapter) puts the passage just before the anchor, where
      // a scan clamped at the chapter start can never look.
      lo = (lo - 900).clamp(0.0, lo);
      debugPrint('[FindAudio] si=$si target@${offset.toInt()}/${total.toInt()} '
          'toc="$tocTitle" audioCh="${audioCh['title']}" '
          '${lo.toStringAsFixed(0)}-${hi.isFinite ? hi.toStringAsFixed(0) : '?'}s '
          'rate=${rate.toStringAsFixed(4)} est=${est.toStringAsFixed(1)}');
    } else {
      // Calibre-split books often have spine sections the TOC never names
      // (toc=null), or titles no audio chapter agrees with. Best fallback:
      // anchor on the nearest PRECEDING section that does map to an audio
      // chapter and pace forward through the intervening text. The whole-book
      // percentage is the last resort - on books with songs or front matter
      // it was measured ~800s off, far outside the probes' scan range.
      double? anchoredEst;
      var anchorStart = 0.0;
      final hrefs = await text.spineHrefs();
      for (var a = si - 1; a >= 0 && a >= si - 8; a--) {
        if (a >= hrefs.length) continue;
        final aTitle = text.chapterForHref(hrefs[a]);
        if (aTitle == null) continue;
        Map<String, dynamic>? aCh;
        for (final ch in audio.chapters) {
          final m = ch as Map<String, dynamic>;
          if (chapterTitlesAgree(m['title'] as String?, aTitle)) {
            aCh = m;
            break;
          }
        }
        if (aCh == null) continue;
        final aStart = (aCh['start'] as num?)?.toDouble() ?? 0;
        final counts = await text.sectionCharCounts(a, si - 1);
        if (counts.length == si - a) {
          final between = counts.fold<double>(0, (x, y) => x + y);
          anchorStart = aStart;
          anchoredEst = aStart + (between + offset) * _fallbackSecPerChar;
          debugPrint('[FindAudio] anchored on si=$a "${aCh['title']}" '
              'start=${aStart.toStringAsFixed(0)} '
              'charsBetween=${between.toInt()} est=${anchoredEst.toStringAsFixed(1)}');
        }
        break;
      }

      if (anchoredEst != null) {
        lo = anchorStart;
        hi = bookEnd;
        rate = _fallbackSecPerChar;
        est = anchoredEst;
      } else if (pct != null && pct > 0 && audio.duration > 0) {
        lo = 0;
        hi = audio.duration;
        rate = _fallbackSecPerChar;
        est = (pct * audio.duration).clamp(0.0, audio.duration);
        debugPrint('[FindAudio] fallback estimate (toc="$tocTitle") '
            'pct=${(pct * 100).toStringAsFixed(2)}% est=${est.toStringAsFixed(1)}');
      } else {
        debugPrint('[FindAudio] no audio chapter matches toc="$tocTitle", '
            'no anchor, no location percentage - giving up');
        return null;
      }
    }
    if (hi.isInfinite) hi = est + 3600;

    // The section's narration length sets how far apart the probes spread:
    // 90s steps suit a short section, a 40-minute chapter wants them wider so
    // five probes cover it instead of one corner.
    final scanStep = (total * rate / 4).clamp(_scanStepSeconds, 300.0);
    final dur = audio.duration;
    final probed = <double>[est];
    var probesLeft = _maxTotalProbes;

    Future<double?> run(String label, double e, double from, double to,
        double pace, int rounds, {double? step}) async {
      if (probesLeft <= 0) return null;
      final n = rounds < probesLeft ? rounds : probesLeft;
      probesLeft -= n;
      debugPrint('[FindAudio] $label est=${e.toStringAsFixed(1)} '
          'window ${from.toStringAsFixed(0)}-${to.toStringAsFixed(0)}s '
          'rounds=$n');
      return _probeForTarget(
        si: si,
        offset: offset,
        estimate: e,
        lo: from,
        hi: to,
        rate: pace,
        duration: dur,
        maxProbes: n,
        scanStepSeconds: step ?? scanStep,
      );
    }

    // A spot this book has already been matched at, in this section or the
    // one either side, beats any chapter-title guess: it is known, and two
    // of them give the real pace between. Probed first, in a window sized to
    // how far the pacing had to reach.
    final sync = await _syncPointCandidate(
        si: si,
        offset: offset,
        total: total,
        fallbackRate: rate,
        top: dur > 0 ? dur : est + 3600);
    if (sync != null) {
      probed.add(sync.est);
      final window = sync.hi - sync.lo;
      final r = await run(sync.label, sync.est, sync.lo, sync.hi, sync.rate, 3,
          step: (window / 3).clamp(45.0, _scanStepSeconds));
      if (r != null) return remember(r);
    }

    final t = await run('anchor', est, lo, hi, rate, _maxProbes);
    if (t != null) return remember(t);

    // The anchor never matched. Fallback candidates, most likely first, two
    // rounds each.
    final extras =
        <({String label, double est, double lo, double hi, double rate})>[];
    final top = dur > 0 ? dur : double.infinity;
    final pctEst = (pct != null && pct > 0 && dur > 0)
        ? (pct * dur).clamp(0.0, dur)
        : null;

    // Where the audio is parked right now. People mostly look up the passage
    // they just heard, so a player position near the estimate or the book
    // percentage is the best lead there is.
    final player = AudioPlayerService();
    if (player.currentItemId == itemId) {
      final now = player.position.inMilliseconds / 1000.0;
      final near = (now - est).abs() <= 1800 ||
          (pctEst != null && (now - pctEst).abs() <= 1800);
      if (near) {
        extras.add((
          label: 'player position',
          est: now,
          lo: (now - 900).clamp(0.0, now),
          hi: (now + 900).clamp(now, top),
          rate: _fallbackSecPerChar,
        ));
      }
    }
    // The whole-book percentage disagreeing with the anchor by more than a
    // few minutes usually means the anchor is the wrong chapter.
    if (pctEst != null && (pctEst - est).abs() > 300) {
      extras.add((
        label: 'book percentage',
        est: pctEst,
        lo: (pctEst - 1200).clamp(0.0, pctEst),
        hi: (pctEst + 1200).clamp(pctEst, dur),
        rate: _fallbackSecPerChar,
      ));
    }
    // The same title elsewhere in the book.
    if (audioChAlt != null) {
      final alt = _chapterAnchorEstimate(audioChAlt, offset, total, bookEnd);
      extras.add((
        label: 'runner-up "${audioChAlt['title']}"',
        est: alt.est,
        lo: alt.lo,
        hi: alt.hi.isFinite ? alt.hi : alt.est + 3600,
        rate: alt.rate,
      ));
    }
    // A chapter-derived pace far from real narration says the audio and
    // ebook chapters are numbered differently (twice too fast means the ebook
    // chapter holds twice the text the audio chapter narrates): try the
    // neighbours, nearest to the book percentage first.
    if (audioCh != null &&
        (anchorRate.isNaN || anchorRate < 0.05 || anchorRate > 0.12)) {
      final idx = audio.chapters.indexOf(audioCh);
      final neighbours = <Map<String, dynamic>>[];
      if (idx > 0) neighbours.add(audio.chapters[idx - 1] as Map<String, dynamic>);
      if (idx >= 0 && idx + 1 < audio.chapters.length) {
        neighbours.add(audio.chapters[idx + 1] as Map<String, dynamic>);
      }
      final withEst = neighbours
          .map((n) => (ch: n, a: _chapterAnchorEstimate(n, offset, total, bookEnd)))
          .toList();
      if (pctEst != null) {
        withEst.sort((x, y) =>
            (x.a.est - pctEst).abs().compareTo((y.a.est - pctEst).abs()));
      }
      for (final n in withEst) {
        extras.add((
          label: 'neighbour "${n.ch['title']}"',
          est: n.a.est,
          lo: n.a.lo,
          hi: n.a.hi.isFinite ? n.a.hi : n.a.est + 3600,
          rate: n.a.rate,
        ));
      }
    }

    for (final c in extras) {
      if (probed.any((p) => (p - c.est).abs() <= 120)) {
        debugPrint('[FindAudio] skip ${c.label}: '
            'est=${c.est.toStringAsFixed(1)} already probed');
        continue;
      }
      probed.add(c.est);
      final r = await run(c.label, c.est, c.lo, c.hi, c.rate, 2);
      if (r != null) return remember(r);
    }
    debugPrint('[FindAudio] no candidate matched');
    return null;
  }

  /// Where the sync points say [offset] in section [si] should be in the
  /// audio. Same-section points first; failing that the last point of the
  /// previous section or the first of the next, paced through the text in
  /// between. Null when nothing recorded is close enough to help.
  Future<({String label, double est, double lo, double hi, double rate})?>
      _syncPointCandidate({
    required int si,
    required double offset,
    required double total,
    required double fallbackRate,
    required double top,
  }) async {
    final pts = SyncPointStore.instance.cached(itemId);
    if (pts.isEmpty) return null;
    final same = pts.where((p) => p.si == si).toList();
    var e = SyncPointEstimator.inSection(same, offset, fallbackRate);
    var label = 'sync points';
    if (e == null) {
      SyncPoint? prev, next;
      for (final p in pts) {
        if (p.si == si - 1 && (prev == null || p.off > prev.off)) prev = p;
        if (p.si == si + 1 && (next == null || p.off < next.off)) next = p;
      }
      if (prev != null) {
        final counts = await text.sectionCharCounts(si - 1, si - 1);
        if (counts.length == 1 && counts.first > 0) {
          final chars = (counts.first - prev.off) + offset;
          if (chars * fallbackRate <= 1800) {
            e = SyncPointEstimator.fromPoint(prev, chars, fallbackRate);
            label = 'sync point in the previous section';
          }
        }
      }
      if (e == null && next != null) {
        final chars = (total - offset) + next.off;
        if (chars * fallbackRate <= 1800) {
          e = SyncPointEstimator.fromPoint(next, -chars, fallbackRate);
          label = 'sync point in the next section';
        }
      }
    }
    if (e == null) return null;
    debugPrint('[FindAudio] $label (${e.how}) from ${pts.length} points: '
        'est=${e.est.toStringAsFixed(1)} rate=${e.rate.toStringAsFixed(4)}');
    return (
      label: '$label (${e.how})',
      est: e.est.clamp(0.0, top),
      lo: e.lo.clamp(0.0, top),
      hi: e.hi.clamp(0.0, top),
      rate: e.rate,
    );
  }

  /// Initial search window and seconds-per-character pacing from an audio
  /// chapter anchor.
  ({double lo, double hi, double rate, double est}) _chapterAnchorEstimate(
      Map<String, dynamic> ch, double offset, double total, double bookEnd) {
    final chStart = (ch['start'] as num?)?.toDouble() ?? 0;
    final chEnd = (ch['end'] as num?)?.toDouble() ?? bookEnd;
    final chRate = (chEnd - chStart) / total;
    if (chRate >= 0.03 && chRate <= 0.2) {
      return (
        lo: chStart,
        hi: chEnd,
        rate: chRate,
        est: chStart + offset * chRate,
      );
    }
    // Mis-tagged audio chapters (a 3-second "chapter" was seen in the wild)
    // give an absurd rate. Trust the chapter START as an anchor, pace the
    // estimate at normal narration speed, leave the end open.
    return (
      lo: chStart,
      hi: bookEnd,
      rate: _fallbackSecPerChar,
      est: chStart + offset * _fallbackSecPerChar,
    );
  }

  /// Probe-transcribes around [estimate], correcting toward the selection at
  /// [offset] each round. Returns the resolved global time, or null when
  /// [maxProbes] rounds never matched the section text.
  Future<double?> _probeForTarget({
    required int si,
    required double offset,
    required double estimate,
    required double lo,
    required double hi,
    required double rate,
    required double duration,
    required int maxProbes,
    required double scanStepSeconds,
  }) async {
    var est = estimate;
    final baseEst = est;
    var scanStep = 0;
    for (var attempt = 0; attempt < maxProbes; attempt++) {
      final maxStart =
          (hi - _probeWindowSeconds) > lo ? hi - _probeWindowSeconds : lo;
      var probeStart = (est - _probeWindowSeconds / 2).clamp(lo, maxStart);
      // A chapter start is usually a file start too. A window centred on it
      // begins in the previous file and gets cut at the boundary, so it only
      // ever hears the end of the last chapter. Start at the boundary instead
      // so the estimate is inside what gets transcribed.
      final boundary = TranscriptionService.instance
          .trackBoundaryBetween(itemId, probeStart, est);
      if (boundary != null) {
        debugPrint('[FindAudio] probe#$attempt window start '
            '${probeStart.toStringAsFixed(1)} -> file boundary '
            '${boundary.toStringAsFixed(1)}');
        probeStart = boundary.clamp(lo, maxStart > boundary ? maxStart : boundary);
      }

      List<({double start, double end, String text})> segs;
      try {
        segs = await TranscriptionService.instance.transcribeWindowSegments(
          itemId: itemId,
          startSeconds: probeStart,
          windowSeconds: _probeWindowSeconds,
          preferAccuracy: false,
        );
      } on TranscriptionException catch (e) {
        // A silent or music-only window transcribes to nothing, and a probe
        // landing at the tail of a track file gets truncated to nearly zero
        // (windows don't span file boundaries) - scan on rather than giving
        // up. Setup problems can't be scanned away.
        if (e.kind != TranscriptionError.empty &&
            e.kind != TranscriptionError.extractFailed) {
          rethrow;
        }
        segs = const [];
      }
      final probeText = segs.map((s) => s.text).join(' ').trim();
      final match =
          probeText.isEmpty ? null : await text.locateTranscriptInSection(si, probeText);
      final fine = match == null ? 0.0 : (match['fine'] as num).toDouble();

      if (match == null || fine < 0.5) {
        // Bad probe (music, silence, or the estimate is off enough that the
        // audio here isn't in this section): scan around the original
        // estimate instead of declining on the first miss.
        scanStep = scanStep >= 0 ? -(scanStep + 1) : -scanStep;
        est = (baseEst + scanStep * scanStepSeconds).clamp(lo, hi);
        debugPrint('[FindAudio] probe#$attempt start=${probeStart.toStringAsFixed(1)} '
            'no usable match (fine=${fine.toStringAsFixed(3)}) - '
            'scanning to ${est.toStringAsFixed(1)}');
        continue;
      }

      final mOff = (match['s'] as num).toDouble();
      final mEnd = (match['e'] as num).toDouble();
      debugPrint('[FindAudio] probe#$attempt start=${probeStart.toStringAsFixed(1)} '
          'match=${mOff.toInt()}-${mEnd.toInt()} '
          'fine=${fine.toStringAsFixed(3)} target=${offset.toInt()}');

      if (offset >= mOff && offset <= mEnd) {
        // Target is inside the probed audio: walk the segments to the one
        // covering the target's share of the matched text.
        final frac = (mEnd - mOff) > 0 ? (offset - mOff) / (mEnd - mOff) : 0.0;
        final lens = segs.map((s) => s.text.length + 1).toList();
        final totalLen = lens.fold<int>(0, (a, b) => a + b);
        final targetChar = frac * totalLen;
        var t = probeStart + segs.last.start;
        var acc = 0.0;
        for (var i = 0; i < segs.length; i++) {
          if (targetChar <= acc + lens[i] || i == segs.length - 1) {
            final inFrac = lens[i] > 0
                ? ((targetChar - acc) / lens[i]).clamp(0.0, 1.0)
                : 0.0;
            t = probeStart + segs[i].start + inFrac * (segs[i].end - segs[i].start);
            break;
          }
          acc += lens[i];
        }
        debugPrint('[FindAudio] resolved t=${t.toStringAsFixed(1)}s');
        return duration > 0 ? t.clamp(0.0, duration) : t;
      }

      // Probe landed off-target: correct by the miss distance and retry. A
      // correction too small to move the next probe means the rate is off -
      // step most of a window toward the target instead.
      var correction = (offset - (mOff + mEnd) / 2) * rate;
      if (correction.abs() < 2.0) {
        correction = correction.isNegative
            ? -_probeWindowSeconds * 0.75
            : _probeWindowSeconds * 0.75;
      }
      est = (est + correction).clamp(lo, hi);
    }
    debugPrint('[FindAudio] gave up after $maxProbes probes');
    return null;
  }
}
