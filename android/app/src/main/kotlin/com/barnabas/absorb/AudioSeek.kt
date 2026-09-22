package com.barnabas.absorb

import android.media.MediaExtractor

/**
 * Seeking an MP3 is guesswork on Android: MediaExtractor works from the bitrate
 * or a Xing table, so on a variable-bitrate file - which most podcasts are - it
 * can land tens of seconds away from the time it was asked for. An MP4/M4B has a
 * real sample table and lands where you point it, which is why this only started
 * to matter once podcast episodes could be bookmarked.
 *
 * Walking frames forward from an undershoot costs nothing but header parsing, so
 * the fix is to seek short on purpose and then step in.
 */
internal object AudioSeek {
    /** Decoders need a little audio before the target to come up to speed. */
    private const val PRE_ROLL_US = 200_000L

    /** How far back to restart from when a seek overshoots the target. */
    private const val BACK_OFF_US = 30_000_000L

    /** Stops a malformed file from spinning the walk forever. */
    private const val MAX_ADVANCE = 200_000

    /** Within this much of the start, decode from zero instead of seeking. */
    private const val NEAR_START_US = 1_000_000L

    /**
     * Leave [extractor] on the frame just before [targetUs], and return the
     * presentation time it actually landed on (-1 if the file ended first).
     * Callers still have to trim the decoded head: the landing frame starts up
     * to [PRE_ROLL_US] early, and nothing here decodes anything.
     */
    fun seekTo(extractor: MediaExtractor, targetUs: Long): Long {
        // Close enough to the start to just decode from it. Worth doing rather
        // than seeking, because timestamps counted from zero are honest even on
        // an MP3 - so the caller's head trim lands on the exact frame. This is
        // the path an [Mp3Slicer] slice takes, its window being half a second in.
        if (targetUs <= NEAR_START_US) {
            extractor.seekTo(0L, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            return 0L
        }
        extractor.seekTo(targetUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
        if (extractor.sampleTime > targetUs) {
            // Overshot even asking for the previous sync point, so the estimate
            // ran long. Restart further back and walk in from there.
            extractor.seekTo(
                (targetUs - BACK_OFF_US).coerceAtLeast(0L),
                MediaExtractor.SEEK_TO_PREVIOUS_SYNC,
            )
        }

        val limitUs = (targetUs - PRE_ROLL_US).coerceAtLeast(0L)
        var steps = 0
        while (steps++ < MAX_ADVANCE) {
            val t = extractor.sampleTime
            if (t < 0) break // ran off the end
            if (t >= limitUs) return t
            if (!extractor.advance()) break
        }

        // Ended up somewhere unusable - fall back to the plain seek so the
        // caller still gets audio, even if it starts in the wrong place.
        extractor.seekTo(targetUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
        return extractor.sampleTime
    }
}
