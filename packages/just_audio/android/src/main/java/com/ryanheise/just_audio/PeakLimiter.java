package com.ryanheise.just_audio;

import java.util.Arrays;

/**
 * Absorb patch: lookahead peak limiter behind the loudness gain. The audio is
 * held back 5 ms so the gain can ease down before a peak comes out and recover
 * slowly after it. Clipping the boosted samples one by one squared off every
 * loud syllable, which came out as static on a book mastered near full scale.
 * All channels share one gain so the stereo image stays put. No Android types
 * in here so it compiles and tests on its own.
 */
final class PeakLimiter {
    static final float CEILING = 0.891f; // -1 dBFS
    private static final float LOOKAHEAD_SEC = 0.005f;
    private static final float RELEASE_SEC = 0.2f;

    private final int channels;
    private final int lookahead;
    private final double releaseCoef;
    private final float[] delay;
    private final float[] smoothed;
    private final float[] minValue;
    private final long[] minFrame;
    private final float[] silence;

    private int delayPos;
    private int filled;
    private int held;
    private int minHead;
    private int minSize;
    private long clock;
    // A double: in a float the last of the recovery is smaller than the
    // rounding step near 1.0 and the gain stalls just short of it.
    private double envelope;
    private int smoothedPos;
    private double smoothedSum;
    private float lastGain;

    PeakLimiter(int sampleRate, int channels) {
        this.channels = channels;
        lookahead = Math.max(1, Math.round(sampleRate * LOOKAHEAD_SEC));
        releaseCoef = 1.0 - Math.exp(-1.0 / (RELEASE_SEC * sampleRate));
        delay = new float[lookahead * channels];
        smoothed = new float[lookahead];
        minValue = new float[lookahead + 2];
        minFrame = new long[lookahead + 2];
        silence = new float[channels];
        reset();
    }

    void reset() {
        delayPos = 0;
        filled = 0;
        held = 0;
        minHead = 0;
        minSize = 0;
        clock = 0;
        envelope = 1.0;
        Arrays.fill(smoothed, 1f);
        smoothedPos = 0;
        smoothedSum = lookahead;
        lastGain = 1f;
    }

    /** Frames taken in and not yet given back. */
    int held() {
        return held;
    }

    /** True once the gain has recovered all the way, so stepping out of the limiter is seamless. */
    boolean isResting() {
        return lastGain >= 0.9999f;
    }

    /**
     * Takes one frame and writes the frame leaving the delay line to out.
     * Returns false while the line is still filling, when out is untouched.
     * With limit off no new reduction is asked for and the gain just recovers.
     */
    boolean push(float[] frame, float[] out, boolean limit) {
        held++;
        boolean emitted = step(frame, out, limit);
        if (emitted) held--;
        return emitted;
    }

    /** Gives back one held frame at the end of the audio; false once empty. */
    boolean drain(float[] out) {
        while (held > 0) {
            if (step(silence, out, true)) {
                if (--held == 0) reset();
                return true;
            }
        }
        return false;
    }

    private boolean step(float[] frame, float[] out, boolean limit) {
        float peak = 0f;
        if (limit) {
            for (int c = 0; c < channels; c++) {
                float magnitude = Math.abs(frame[c]);
                if (magnitude > peak) peak = magnitude;
            }
        }
        float gain = advance(peak);
        lastGain = gain;
        boolean emit = filled == lookahead;
        int base = delayPos * channels;
        for (int c = 0; c < channels; c++) {
            if (emit) out[c] = delay[base + c] * gain;
            delay[base + c] = frame[c];
        }
        if (++delayPos == lookahead) delayPos = 0;
        if (!emit) filled++;
        return emit;
    }

    // The gain for the frame now leaving the delay line. The lowest gain any
    // frame still in the line needs is held, released slowly, then averaged
    // over the lookahead, so the drop is a ramp that has always finished by
    // the time the peak that asked for it comes out.
    private float advance(float peak) {
        float need = peak > CEILING ? CEILING / peak : 1f;
        int cap = minValue.length;
        while (minSize > 0 && minValue[(minHead + minSize - 1) % cap] >= need) minSize--;
        int tail = (minHead + minSize) % cap;
        minValue[tail] = need;
        minFrame[tail] = clock;
        minSize++;
        if (minFrame[minHead] < clock - lookahead) {
            minHead = (minHead + 1) % cap;
            minSize--;
        }
        clock++;
        float floor = minValue[minHead];
        envelope = floor < envelope ? floor : envelope + (floor - envelope) * releaseCoef;

        float stored = (float) envelope;
        smoothedSum += stored - smoothed[smoothedPos];
        smoothed[smoothedPos] = stored;
        if (++smoothedPos == lookahead) {
            smoothedPos = 0;
            // Start the running sum over each lap so rounding never builds up.
            double exact = 0;
            for (float value : smoothed) exact += value;
            smoothedSum = exact;
        }
        return (float) (smoothedSum / lookahead);
    }
}
