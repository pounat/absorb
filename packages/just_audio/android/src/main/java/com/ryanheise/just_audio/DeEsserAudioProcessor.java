package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.BaseAudioProcessor;

import java.nio.ByteBuffer;

/**
 * Split-band de-esser: a bandpass sidechain (~4-9 kHz, centered 6 kHz)
 * detects sibilance energy; when its envelope exceeds a strength-dependent
 * threshold, up to 12 dB of the bandpassed signal is subtracted from the
 * output, so only the sibilance band is attenuated. Mirrors the iOS tap
 * implementation in ios/Runner/Audio/AudioEQProcessor.m so both platforms
 * sound the same.
 *
 * Sits after SonicAudioProcessor (speed) and the ChannelMixingAudioProcessor
 * (channel normalization) in the sink chain, so input is post-speed 16-bit
 * PCM, normally stereo. Always active so strength can change live without a
 * pipeline rebuild (same trick as the mono matrix swap).
 */
public final class DeEsserAudioProcessor extends BaseAudioProcessor {

    /** Strength 0-1000, written from the platform channel thread. */
    private volatile int strength;

    private int lastAppliedStrength = -1;
    private boolean bypass;
    private int channelCount;

    // RBJ constant-0dB-peak-gain bandpass coefficients (b1 == 0).
    private float b0, b2, a1, a2;
    // Per-channel biquad delay lines and envelope followers.
    private float[] x1, x2, y1, y2, env;
    private float attackCoeff, releaseCoeff;
    private float thrLin, kneeInv, kMax;

    public void setStrength(int strength) {
        this.strength = Math.max(0, Math.min(1000, strength));
    }

    @Override
    protected AudioFormat onConfigure(AudioFormat inputAudioFormat) {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
            // Never break playback over an effect. The chain only produces
            // 16-bit here (Sonic precedes us and requires it), so this is
            // belt-and-braces; NOT_SET just deactivates the processor.
            return AudioFormat.NOT_SET;
        }
        channelCount = inputAudioFormat.channelCount;
        x1 = new float[channelCount];
        x2 = new float[channelCount];
        y1 = new float[channelCount];
        y2 = new float[channelCount];
        env = new float[channelCount];

        float fs = inputAudioFormat.sampleRate;
        // Below 14 kHz there is no headroom for a ~6 kHz sibilance band
        // (an unclamped biquad near Nyquist blows up), so stay inert.
        bypass = fs < 14000f;
        if (!bypass) {
            float f0 = Math.min(6000f, fs * 0.45f);
            double w0 = 2.0 * Math.PI * f0 / fs;
            double alpha = Math.sin(w0) / (2.0 * 1.1);
            double a0 = 1.0 + alpha;
            b0 = (float) (alpha / a0);
            b2 = (float) (-alpha / a0);
            a1 = (float) (-2.0 * Math.cos(w0) / a0);
            a2 = (float) ((1.0 - alpha) / a0);
        }
        attackCoeff = (float) (1.0 - Math.exp(-1.0 / (0.001 * fs)));
        releaseCoeff = (float) (1.0 - Math.exp(-1.0 / (0.060 * fs)));
        lastAppliedStrength = -1;
        return inputAudioFormat;
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        int remaining = inputBuffer.remaining();
        if (remaining == 0) return;
        ByteBuffer out = replaceOutputBuffer(remaining);

        int s = strength;
        if (s == 0 || bypass) {
            if (lastAppliedStrength != 0) {
                clearDspState();
                lastAppliedStrength = 0;
            }
            out.put(inputBuffer);
            out.flip();
            return;
        }
        if (s != lastAppliedStrength) {
            float sf = s / 1000f;
            thrLin = (float) Math.pow(10.0, (-30.0 - 12.0 * sf) / 20.0);
            kMax = (float) (1.0 - Math.pow(10.0, -(12.0 * sf) / 20.0));
            // 12 dB soft ramp above threshold, precomputed in linear domain
            // so the per-sample path stays free of pow/exp.
            kneeInv = (float) (1.0 / (thrLin * (Math.pow(10.0, 12.0 / 20.0) - 1.0)));
            lastAppliedStrength = s;
        }

        int frameBytes = 2 * channelCount;
        while (inputBuffer.remaining() >= frameBytes) {
            for (int ch = 0; ch < channelCount; ch++) {
                float x = inputBuffer.getShort() * (1f / 32768f);

                float bp = b0 * x + b2 * x2[ch] - a1 * y1[ch] - a2 * y2[ch];
                x2[ch] = x1[ch];
                x1[ch] = x;
                y2[ch] = y1[ch];
                y1[ch] = bp;

                float mag = bp < 0 ? -bp : bp;
                float e = env[ch];
                e += ((mag > e) ? attackCoeff : releaseCoeff) * (mag - e);
                env[ch] = e;

                float frac = (e - thrLin) * kneeInv;
                if (frac > 0f) {
                    if (frac > 1f) frac = 1f;
                    x -= (kMax * frac) * bp;
                }

                if (x > 32767f / 32768f) x = 32767f / 32768f;
                else if (x < -1f) x = -1f;
                out.putShort((short) (x * 32768f));
            }
        }
        // Pass any partial frame bytes through untouched (shouldn't occur).
        if (inputBuffer.hasRemaining()) out.put(inputBuffer);
        out.flip();
    }

    @Override
    protected void onFlush() {
        // Called on seek/speed change; stale envelope/filter state would
        // cause a brief gain dip on the new audio.
        clearDspState();
    }

    @Override
    protected void onReset() {
        clearDspState();
    }

    private void clearDspState() {
        if (env == null) return;
        java.util.Arrays.fill(x1, 0f);
        java.util.Arrays.fill(x2, 0f);
        java.util.Arrays.fill(y1, 0f);
        java.util.Arrays.fill(y2, 0f);
        java.util.Arrays.fill(env, 0f);
    }
}
