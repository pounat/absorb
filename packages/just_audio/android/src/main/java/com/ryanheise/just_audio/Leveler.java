package com.ryanheise.just_audio;

/**
 * Absorb patch: the loudness slider as an automatic level, the way a car
 * radio's auto volume works. Quiet narration is pulled up toward a target
 * peak and loud narration is left alone, so every book comes out at about
 * the same level without the slider being tuned per book. The slider caps
 * how much gain may be added; at zero nothing is added.
 *
 * The level is followed on speech only. A short-term peak that sits more
 * than 30 dB under the recent level is a pause, and the gain holds through
 * it instead of creeping up and bursting on the next sentence. Gain drops
 * within 10 ms when a louder passage arrives and climbs at 8 dB a second
 * when a quieter one does.
 *
 * No Android types in here so it compiles and tests on its own.
 */
final class Leveler {
    /** Peaks are pulled up toward this level, -3 dBFS. */
    static final float TARGET = 0.708f;
    private static final float PAUSE_RATIO = 0.0316f;
    private static final float FLOOR = 0.001f;
    private static final float FAST_SEC = 0.03f;
    private static final float FOLLOW_SEC = 1.0f;
    private static final float DROP_SEC = 0.01f;
    private static final float RISE_DB_PER_SEC = 8f;

    private final float fastCoef;
    private final double followCoef;
    private final float dropCoef;
    private final float riseStep;
    private float fast;
    private double envelope;
    private float gain = 1f;

    Leveler(int sampleRate) {
        fastCoef = (float) Math.exp(-1.0 / (FAST_SEC * sampleRate));
        followCoef = Math.exp(-1.0 / (FOLLOW_SEC * sampleRate));
        dropCoef = (float) (1.0 - Math.exp(-1.0 / (DROP_SEC * sampleRate)));
        riseStep = (float) Math.pow(10.0, RISE_DB_PER_SEC / 20.0 / sampleRate);
    }

    float gain() {
        return gain;
    }

    void reset() {
        fast = 0f;
        envelope = 0;
        gain = 1f;
    }

    /**
     * The gain for one frame whose loudest channel has magnitude peak, with
     * maxGain the most the slider allows (1 = off).
     */
    float next(float peak, float maxGain) {
        fast = peak > fast ? peak : fast * fastCoef;
        if (fast >= envelope) {
            envelope = fast;
        } else if (fast > envelope * PAUSE_RATIO) {
            envelope *= followCoef;
            if (envelope < fast) envelope = fast;
        }
        float wanted;
        if (envelope < FLOOR) {
            wanted = Math.min(gain, maxGain);
        } else {
            wanted = (float) Math.min(maxGain, Math.max(1.0, TARGET / envelope));
        }
        if (wanted < gain) {
            gain += (wanted - gain) * dropCoef;
            if (gain - wanted < 1e-4f) gain = wanted;
        } else if (wanted > gain) {
            gain = Math.min(wanted, gain * riseStep);
        }
        return gain;
    }
}
