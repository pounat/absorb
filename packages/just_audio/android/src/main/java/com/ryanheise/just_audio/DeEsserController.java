package com.ryanheise.just_audio;

/**
 * Static bridge so external code (e.g. MainActivity) can set the de-esser
 * strength without directly importing AudioPlayer (which causes classpath
 * issues). Mirrors MonoController, plus a replay of the last strength on
 * register so a recreated ExoPlayer inherits the current value before the
 * Dart side's next push.
 */
public class DeEsserController {
    public interface Callback {
        void setStrength(int strength);
    }

    private static volatile Callback sCallback;
    private static volatile int sLastStrength = 0;

    public static void register(Callback callback) {
        sCallback = callback;
        if (callback != null) callback.setStrength(sLastStrength);
    }

    public static void setStrength(int strength) {
        sLastStrength = strength;
        Callback cb = sCallback;
        if (cb != null) cb.setStrength(strength);
    }
}
