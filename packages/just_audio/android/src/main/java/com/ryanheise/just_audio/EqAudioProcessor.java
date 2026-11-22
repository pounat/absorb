package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.BaseAudioProcessor;
import java.nio.ByteBuffer;

/**
 * Absorb patch: the five-band equalizer and the bass boost inside the
 * ExoPlayer audio sink, the same biquads the iOS tap runs. Android's session
 * Equalizer and BassBoost die with the activity and on phones whose effect
 * stack is broken; this runs on every sample regardless. The bands sit where
 * the platform effect reports them on most phones, so saved presets carry
 * over. With the bands off and no bass boost the audio passes through
 * untouched.
 */
public final class EqAudioProcessor extends BaseAudioProcessor {
    public static final int BANDS = 5;
    public static final int[] BAND_HZ = {60, 230, 910, 3600, 14000};
    private static final float BAND_Q = 1.4f;
    private static final float BASS_HZ = 120f;
    private static final float BASS_MAX_DB = 12f;
    private static final int BASS = BANDS;

    private static volatile boolean sEnabled;
    private static final int[] sBandMb = new int[BANDS];
    private static volatile int sBassStrength;
    private static volatile int sVersion;

    public static void setEnabled(boolean enabled) {
        sEnabled = enabled;
        sVersion++;
    }

    /** One band's gain in millibels (100 mB = 1 dB). */
    public static void setBandMb(int band, int mb) {
        if (band < 0 || band >= BANDS) return;
        sBandMb[band] = Math.max(-1500, Math.min(1500, mb));
        sVersion++;
    }

    /** Bass boost strength 0-1000, mapped to a low shelf of 0-12 dB at 120 Hz. */
    public static void setBassStrength(int strength) {
        sBassStrength = Math.max(0, Math.min(1000, strength));
        sVersion++;
    }

    private final float[][] coef = new float[BANDS + 1][5];
    private float[][][] delay;
    private int version = -1;
    private boolean bandsOn;
    private boolean bassOn;
    private boolean is16Bit;
    private int channels;
    private int sampleRate;
    private int frameBytes;

    @Override
    public AudioFormat onConfigure(AudioFormat inputAudioFormat)
            throws UnhandledAudioFormatException {
        int encoding = inputAudioFormat.encoding;
        if (encoding != C.ENCODING_PCM_16BIT && encoding != C.ENCODING_PCM_FLOAT) {
            throw new UnhandledAudioFormatException(inputAudioFormat);
        }
        return inputAudioFormat;
    }

    @Override
    protected void onFlush() {
        if (!isActive()) return;
        channels = inputAudioFormat.channelCount;
        sampleRate = inputAudioFormat.sampleRate;
        is16Bit = inputAudioFormat.encoding == C.ENCODING_PCM_16BIT;
        frameBytes = channels * (is16Bit ? 2 : 4);
        delay = new float[BANDS + 1][channels][4];
        version = -1;
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        int remaining = inputBuffer.remaining();
        if (remaining == 0) return;
        if (version != sVersion) rebuild();
        ByteBuffer output = replaceOutputBuffer(remaining);
        if (!bandsOn && !bassOn) {
            output.put(inputBuffer);
            output.flip();
            return;
        }
        while (inputBuffer.remaining() >= frameBytes) {
            for (int c = 0; c < channels; c++) {
                float sample = is16Bit ? inputBuffer.getShort() / 32768f : inputBuffer.getFloat();
                if (bandsOn) {
                    for (int band = 0; band < BANDS; band++) {
                        sample = biquad(coef[band], delay[band][c], sample);
                    }
                }
                if (bassOn) sample = biquad(coef[BASS], delay[BASS][c], sample);
                if (is16Bit) {
                    int value = Math.round(sample * 32767f);
                    output.putShort((short) Math.max(-32768, Math.min(32767, value)));
                } else {
                    output.putFloat(sample);
                }
            }
        }
        inputBuffer.position(inputBuffer.limit());
        output.flip();
    }

    private static float biquad(float[] c, float[] d, float x) {
        float y = c[0] * x + c[1] * d[0] + c[2] * d[1] - c[3] * d[2] - c[4] * d[3];
        d[1] = d[0];
        d[0] = x;
        d[3] = d[2];
        d[2] = y;
        return y;
    }

    private void rebuild() {
        version = sVersion;
        // A peaking biquad at or above Nyquist puts its poles outside the unit
        // circle and the output turns to NaN, so such a band is left flat.
        // Low-bitrate AAC decodes at 22050 Hz, where the 14 kHz band trips it.
        float maxHz = sampleRate * 0.5f * 0.95f;
        boolean any = false;
        for (int band = 0; band < BANDS; band++) {
            float db = sEnabled ? sBandMb[band] / 100f : 0f;
            if (db != 0f) any = true;
            if (db == 0f || BAND_HZ[band] >= maxHz) {
                unity(coef[band]);
            } else {
                peaking(coef[band], BAND_HZ[band], db, BAND_Q, sampleRate);
            }
        }
        bandsOn = sEnabled && any;
        float bassDb = sBassStrength / 1000f * BASS_MAX_DB;
        bassOn = bassDb > 0f && BASS_HZ < maxHz;
        if (bassOn) {
            lowShelf(coef[BASS], BASS_HZ, bassDb, sampleRate);
        } else {
            unity(coef[BASS]);
        }
    }

    private static void unity(float[] c) {
        c[0] = 1f;
        c[1] = 0f;
        c[2] = 0f;
        c[3] = 0f;
        c[4] = 0f;
    }

    private static void peaking(float[] c, float f0, float dbGain, float q, float fs) {
        double a = Math.pow(10.0, dbGain / 40.0);
        double w0 = 2.0 * Math.PI * f0 / fs;
        double sinw = Math.sin(w0);
        double cosw = Math.cos(w0);
        double alpha = sinw / (2.0 * q);
        double a0 = 1.0 + alpha / a;
        c[0] = (float) ((1.0 + alpha * a) / a0);
        c[1] = (float) ((-2.0 * cosw) / a0);
        c[2] = (float) ((1.0 - alpha * a) / a0);
        c[3] = (float) ((-2.0 * cosw) / a0);
        c[4] = (float) ((1.0 - alpha / a) / a0);
    }

    private static void lowShelf(float[] c, float f0, float dbGain, float fs) {
        double a = Math.pow(10.0, dbGain / 40.0);
        double w0 = 2.0 * Math.PI * f0 / fs;
        double sinw = Math.sin(w0);
        double cosw = Math.cos(w0);
        double alpha = sinw / 2.0 * Math.sqrt((a + 1.0 / a) * (1.0 / 0.7071 - 1.0) + 2.0);
        double sqrtA2alpha = 2.0 * Math.sqrt(a) * alpha;
        double a0 = (a + 1.0) + (a - 1.0) * cosw + sqrtA2alpha;
        c[0] = (float) ((a * ((a + 1.0) - (a - 1.0) * cosw + sqrtA2alpha)) / a0);
        c[1] = (float) ((2.0 * a * ((a - 1.0) - (a + 1.0) * cosw)) / a0);
        c[2] = (float) ((a * ((a + 1.0) - (a - 1.0) * cosw - sqrtA2alpha)) / a0);
        c[3] = (float) ((-2.0 * ((a - 1.0) + (a + 1.0) * cosw)) / a0);
        c[4] = (float) (((a + 1.0) + (a - 1.0) * cosw - sqrtA2alpha) / a0);
    }
}
