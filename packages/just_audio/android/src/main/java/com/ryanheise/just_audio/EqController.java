package com.ryanheise.just_audio;

/**
 * Static bridge so MainActivity can drive the in-sink equalizer without
 * seeing media3 types on its classpath (same reason GainController exists).
 */
public class EqController {
    public static final int BANDS = EqAudioProcessor.BANDS;
    public static final int[] BAND_HZ = EqAudioProcessor.BAND_HZ;

    public static void setEnabled(boolean enabled) {
        EqAudioProcessor.setEnabled(enabled);
    }

    public static void setBandMb(int band, int mb) {
        EqAudioProcessor.setBandMb(band, mb);
    }

    public static void setBassStrength(int strength) {
        EqAudioProcessor.setBassStrength(strength);
    }
}
