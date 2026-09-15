package com.ryanheise.just_audio;

import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.common.audio.BaseAudioProcessor;
import androidx.media3.exoplayer.audio.SilenceSkippingAudioProcessor;
import androidx.media3.common.util.UnstableApi;
import java.nio.ByteBuffer;

/**
 * Dynamically configurable silence-skipping processor wrapping Media3's
 * SilenceSkippingAudioProcessor.
 */
@UnstableApi
public class AbsorbSilenceAudioProcessor extends BaseAudioProcessor {

    public static final int DEFAULT_PADDING_MS = 20;
    public static final int DEFAULT_THRESHOLD_DB = -30;

    private boolean enabled = false;
    private int paddingMs = DEFAULT_PADDING_MS;
    private int thresholdDb = DEFAULT_THRESHOLD_DB;
    private SilenceSkippingAudioProcessor delegate;

    public synchronized void setParameters(boolean enabled, int paddingMs, int thresholdDb) {
        this.enabled = enabled;
        this.paddingMs = Math.max(0, paddingMs);
        this.thresholdDb = thresholdDb;
        updateDelegate();
    }

    private void updateDelegate() {
        short thresholdLevel = (short) Math.max(1, (int) Math.round(Math.pow(10.0, thresholdDb / 20.0) * 32767.0));
        long paddingUs = (long) paddingMs * 1000L;
        delegate = new SilenceSkippingAudioProcessor(150_000L, paddingUs, thresholdLevel);
        delegate.setEnabled(enabled);
        if (inputAudioFormat != null && inputAudioFormat != AudioFormat.NOT_SET) {
            try {
                delegate.configure(inputAudioFormat);
                delegate.flush();
            } catch (Exception ignored) {}
        }
    }

    @Override
    protected AudioFormat onConfigure(AudioFormat inputAudioFormat) throws UnhandledAudioFormatException {
        if (delegate == null) updateDelegate();
        return delegate.configure(inputAudioFormat);
    }

    @Override
    public boolean isActive() {
        return enabled && delegate != null && delegate.isActive();
    }

    @Override
    public void queueInput(ByteBuffer inputBuffer) {
        if (delegate != null) {
            delegate.queueInput(inputBuffer);
        }
    }

    @Override
    public ByteBuffer getOutput() {
        return delegate != null ? delegate.getOutput() : EMPTY_BUFFER;
    }

    @Override
    public boolean isEnded() {
        return delegate != null ? delegate.isEnded() : super.isEnded();
    }

    @Override
    protected void onFlush() {
        if (delegate != null) delegate.flush();
    }

    @Override
    protected void onReset() {
        if (delegate != null) delegate.reset();
    }
}
