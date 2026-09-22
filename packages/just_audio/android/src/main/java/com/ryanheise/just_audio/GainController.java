package com.ryanheise.just_audio;

/**
 * Static bridge so MainActivity can set the loudness gain without seeing
 * media3 types on its classpath (same reason MonoController exists).
 */
public class GainController {
    public static void setGainMb(int gainMb) {
        GainAudioProcessor.setGainMb(gainMb);
    }
}
