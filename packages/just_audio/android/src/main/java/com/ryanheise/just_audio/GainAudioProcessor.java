package com.ryanheise.just_audio;

import androidx.media3.common.C;
import androidx.media3.common.audio.BaseAudioProcessor;
import java.nio.ByteBuffer;

/**
 * Absorb patch: the EQ loudness slider applied inside the ExoPlayer audio
 * sink, the way the iOS tap applies it. Android's LoudnessEnhancer lives on
 * the audio session, so it dies with the activity and on phones whose effect
 * stack is broken; this runs on every sample regardless. The slider sets how
 * much gain the Leveler may add to bring quiet narration up, and a lookahead
 * limiter (PeakLimiter) keeps the result under full scale. With the slider at
 * zero the audio passes through untouched.
 */
public final class GainAudioProcessor extends BaseAudioProcessor {
    private static volatile float sGain = 1f;

    private PeakLimiter limiter;
    private Leveler leveler;
    private float[] frameIn;
    private float[] frameOut;
    private boolean is16Bit;
    private int frameBytes;

    /** The most gain the leveler may add, in millibels (100 mB = 1 dB); zero or less is off. */
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
        leveler = new Leveler(sampleRate);
        frameIn = new float[channels];
        frameOut = new float[channels];
    }

    @Override
    protected void onReset() {
        limiter = null;
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        int remaining = inputBuffer.remaining();
        if (remaining == 0) return;
        float maxGain = sGain;
        // At zero the limiter stops asking for reduction and only recovers, so
        // a hot master is not held down with the boost off.
        boolean unity = limiter == null || (maxGain == 1f && leveler.gain() == 1f);
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
            float peak = 0f;
            for (int c = 0; c < channels; c++) {
                float sample = is16Bit ? inputBuffer.getShort() / 32768f : inputBuffer.getFloat();
                frameIn[c] = sample;
                float magnitude = Math.abs(sample);
                if (magnitude > peak) peak = magnitude;
            }
            float gain = leveler.next(peak, maxGain);
            for (int c = 0; c < channels; c++) frameIn[c] *= gain;
            if (limiter.push(frameIn, frameOut, !unity)) writeFrame(output);
        }
        inputBuffer.position(inputBuffer.limit());
        output.flip();
    }

    // The limiter runs 20 ms behind, so the end of the audio is still inside
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
