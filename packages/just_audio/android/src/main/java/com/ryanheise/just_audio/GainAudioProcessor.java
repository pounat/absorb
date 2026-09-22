package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.BaseAudioProcessor;
import java.nio.ByteBuffer;

/**
 * Absorb patch: the EQ loudness slider as plain sample gain inside the
 * ExoPlayer audio sink, the way the iOS tap applies it. Android's
 * LoudnessEnhancer is a compressor that leaves narration already peaking near
 * full scale almost untouched, and it lives on the audio session, so it dies
 * with the activity and on phones whose effect stack is broken. This runs on
 * every sample regardless. A lookahead limiter (PeakLimiter) keeps the boosted
 * peaks under full scale. With the slider at zero the audio passes through
 * untouched.
 */
public final class GainAudioProcessor extends BaseAudioProcessor {
    private static final float GAIN_SMOOTH_SEC = 0.02f;

    private static volatile float sGain = 1f;

    private PeakLimiter limiter;
    private float[] frameIn;
    private float[] frameOut;
    private boolean is16Bit;
    private int frameBytes;
    private float gain = 1f;
    private float gainCoef;

    /** Gain in millibels (100 mB = 1 dB); zero or less is unity. */
    public static void setGainMb(int gainMb) {
        sGain = gainMb <= 0 ? 1f : (float) Math.pow(10.0, gainMb / 2000.0);
    }

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
        if (!isActive()) {
            limiter = null;
            return;
        }
        int channels = inputAudioFormat.channelCount;
        int sampleRate = inputAudioFormat.sampleRate;
        is16Bit = inputAudioFormat.encoding == C.ENCODING_PCM_16BIT;
        frameBytes = channels * (is16Bit ? 2 : 4);
        limiter = new PeakLimiter(sampleRate, channels);
        frameIn = new float[channels];
        frameOut = new float[channels];
        gain = sGain;
        gainCoef = (float) (1.0 - Math.exp(-1.0 / (GAIN_SMOOTH_SEC * sampleRate)));
    }

    @Override
    protected void onReset() {
        limiter = null;
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        int remaining = inputBuffer.remaining();
        if (remaining == 0) return;
        float target = sGain;
        // At zero the limiter stops asking for reduction and only recovers, so
        // a hot master is not held down with the boost off.
        boolean unity = target == 1f && gain == 1f;
        if (limiter == null || (unity && limiter.isResting())) {
            // Slider at zero and the limiter has let go. Anything it still
            // holds goes out first so no audio is dropped.
            int heldBytes = limiter == null ? 0 : limiter.held() * frameBytes;
            ByteBuffer output = replaceOutputBuffer(heldBytes + remaining);
            if (heldBytes > 0) drainInto(output);
            output.put(inputBuffer);
            output.flip();
            return;
        }
        ByteBuffer output = replaceOutputBuffer(remaining);
        int channels = frameIn.length;
        while (inputBuffer.remaining() >= frameBytes) {
            // Ease toward the slider so dragging it never steps the level.
            gain += (target - gain) * gainCoef;
            if (Math.abs(target - gain) < 1e-4f) gain = target;
            for (int c = 0; c < channels; c++) {
                float sample = is16Bit ? inputBuffer.getShort() / 32768f : inputBuffer.getFloat();
                frameIn[c] = sample * gain;
            }
            if (limiter.push(frameIn, frameOut, !unity)) writeFrame(output);
        }
        inputBuffer.position(inputBuffer.limit());
        output.flip();
    }

    // The limiter runs 5 ms behind, so the end of the audio is still inside
    // it when the input stops. Same shape as media3's TrimmingAudioProcessor.
    @Override
    public ByteBuffer getOutput() {
        if (super.isEnded() && limiter != null && limiter.held() > 0) {
            ByteBuffer output = replaceOutputBuffer(limiter.held() * frameBytes);
            drainInto(output);
            output.flip();
        }
        return super.getOutput();
    }

    @Override
    public boolean isEnded() {
        return super.isEnded() && (limiter == null || limiter.held() == 0);
    }

    private void drainInto(ByteBuffer output) {
        while (limiter.drain(frameOut)) writeFrame(output);
    }

    private void writeFrame(ByteBuffer output) {
        for (float sample : frameOut) {
            if (is16Bit) {
                int value = Math.round(sample * 32767f);
                output.putShort((short) Math.max(-32768, Math.min(32767, value)));
            } else {
                output.putFloat(Math.max(-1f, Math.min(1f, sample)));
            }
        }
    }
}
