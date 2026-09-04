package com.ryanheise.just_audio;

/**
 * Static bridge so external code (e.g. MainActivity) can update silence skipping
 * parameters without directly importing AudioPlayer.
 */
public class AbsorbSilenceController {
    public interface Callback {
        void setSilenceParameters(boolean enabled, int paddingMs, int thresholdDb);
    }

    private static volatile Callback sCallback;

    public static void register(Callback callback) {
        sCallback = callback;
    }

    public static void setParameters(boolean enabled, int paddingMs, int thresholdDb) {
        Callback cb = sCallback;
        if (cb != null) cb.setSilenceParameters(enabled, paddingMs, thresholdDb);
    }
}
