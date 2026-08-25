package com.barnabas.absorb

import android.content.Context
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Extracts a time window of an audiobook file and writes it as an AAC .m4a clip,
 * using only the platform MediaCodec/MediaMuxer stack (no ffmpeg). Decodes the
 * window to PCM, then re-encodes to AAC and muxes into an mp4/m4a container.
 *
 * Source can be a local file path, an Android SAF content:// URI, or an http(s)
 * URL (streamed books) - MediaExtractor range-requests just the window in the
 * streamed case, so we never download the whole track. Mono and stereo pass
 * through; anything with more channels is downmixed to mono. Runs off the main
 * thread (the caller spawns a worker).
 */
object AudioClipExporter {
    private const val TAG = "AbsorbClip"
    private const val TIMEOUT_US = 10_000L
    private const val BIT_RATE = 128_000
    private const val AAC_MIME = "audio/mp4a-latm"

    fun exportM4a(
        context: Context,
        source: String,
        isLocal: Boolean,
        headers: Map<String, String>?,
        startSeconds: Double,
        durationSeconds: Double,
        outPath: String,
    ): Boolean {
        // An MP3 can't be seeked accurately (see [Mp3Slicer]), so cut the window
        // out by frame count first and decode that instead. Anything else - an
        // M4B book, a streamed URL - goes straight through untouched.
        val sliced = if (isLocal) Mp3Slicer.prepare(context, source, startSeconds, durationSeconds) else null
        return try {
            val decoded = decodeWindow(
                context,
                sliced?.path ?: source,
                isLocal,
                headers,
                sliced?.startSeconds ?: startSeconds,
                durationSeconds,
            )
            if (decoded == null || decoded.pcm.isEmpty()) {
                Log.e(TAG, "no PCM decoded from clip window")
                return false
            }
            encodeM4a(outPath, decoded.pcm, decoded.sampleRate, decoded.channels)
            Log.d(TAG, "clip ok: ${decoded.pcm.size} PCM bytes @${decoded.sampleRate}Hz/${decoded.channels}ch -> $outPath")
            true
        } catch (e: Exception) {
            Log.e(TAG, "exportM4a failed: ${e.message}", e)
            try { File(outPath).delete() } catch (_: Exception) {}
            false
        } finally {
            sliced?.temp?.delete()
        }
    }

    private class Decoded(val pcm: ByteArray, val sampleRate: Int, val channels: Int)

    private fun decodeWindow(
        context: Context,
        source: String,
        isLocal: Boolean,
        headers: Map<String, String>?,
        startSeconds: Double,
        durationSeconds: Double,
    ): Decoded? {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            when {
                isLocal && source.startsWith("content://") ->
                    extractor.setDataSource(context, Uri.parse(source), null)
                !isLocal ->
                    extractor.setDataSource(source, headers ?: emptyMap())
                else ->
                    extractor.setDataSource(source)
            }

            val trackIndex = selectAudioTrack(extractor)
            if (trackIndex < 0) {
                Log.e(TAG, "no audio track in $source")
                return null
            }
            extractor.selectTrack(trackIndex)
            val inFormat = extractor.getTrackFormat(trackIndex)
            val mime = inFormat.getString(MediaFormat.KEY_MIME) ?: return null
            val srcChannels = if (inFormat.containsKey(MediaFormat.KEY_CHANNEL_COUNT))
                inFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT) else 1
            // Preserve mono/stereo; downmix anything wider to mono (matches how
            // the rest of the app collapses multichannel output).
            val target = if (srcChannels in 1..2) srcChannels else 1

            val startUs = (startSeconds * 1_000_000L).toLong()
            val durationUs = (durationSeconds * 1_000_000L).toLong()
            val landedUs = AudioSeek.seekTo(extractor, startUs)
            if (landedUs in 0 until startUs - 1_000_000L) {
                Log.d(TAG, "seek landed ${(startUs - landedUs) / 1000}ms early, trimming the head")
            }

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(inFormat, null, null, 0)
            codec.start()

            val info = MediaCodec.BufferInfo()
            var sawInputEOS = false
            var sawOutputEOS = false
            var outRate = if (inFormat.containsKey(MediaFormat.KEY_SAMPLE_RATE))
                inFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE) else 44100
            var outChannels = srcChannels
            // AudioFormat.ENCODING_PCM_16BIT == 2, ENCODING_PCM_FLOAT == 4
            var pcmEncoding = if (inFormat.containsKey(MediaFormat.KEY_PCM_ENCODING))
                inFormat.getInteger(MediaFormat.KEY_PCM_ENCODING) else 2

            val out = ByteArrayOutputStream()
            var collectedUs = 0L

            while (!sawOutputEOS) {
                if (!sawInputEOS) {
                    val inIndex = codec.dequeueInputBuffer(TIMEOUT_US)
                    if (inIndex >= 0) {
                        val inBuf = codec.getInputBuffer(inIndex)!!
                        val sampleSize = extractor.readSampleData(inBuf, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            sawInputEOS = true
                        } else {
                            codec.queueInputBuffer(inIndex, 0, sampleSize, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                val outIndex = codec.dequeueOutputBuffer(info, TIMEOUT_US)
                if (outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val of = codec.outputFormat
                    if (of.containsKey(MediaFormat.KEY_SAMPLE_RATE)) outRate = of.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    if (of.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) outChannels = of.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    if (of.containsKey(MediaFormat.KEY_PCM_ENCODING)) pcmEncoding = of.getInteger(MediaFormat.KEY_PCM_ENCODING)
                } else if (outIndex >= 0) {
                    val outBuf = codec.getOutputBuffer(outIndex)
                    if (outBuf != null && info.size > 0) {
                        // Decoding starts on a frame boundary at or before the
                        // requested time, so drop whatever came out ahead of it -
                        // otherwise the clip starts early and runs short.
                        val aheadUs = startUs - info.presentationTimeUs
                        val skipFrames =
                            if (aheadUs > 0) (aheadUs * outRate / 1_000_000L).toInt() else 0
                        appendInterleaved(outBuf, info, outChannels, target, pcmEncoding, out, skipFrames)
                        collectedUs = out.size().toLong() * 1_000_000L / (outRate.toLong() * target * 2)
                    }
                    codec.releaseOutputBuffer(outIndex, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) sawOutputEOS = true
                    if (durationUs > 0 && collectedUs >= durationUs) sawOutputEOS = true
                }
            }
            return Decoded(out.toByteArray(), outRate, target)
        } finally {
            try { codec?.stop() } catch (_: Exception) {}
            try { codec?.release() } catch (_: Exception) {}
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    /**
     * Append decoded frames as 16-bit little-endian PCM with [target] channels.
     * [skipFrames] drops that many frames off the front, for a buffer that
     * starts before the clip the caller asked for.
     */
    private fun appendInterleaved(
        buf: ByteBuffer,
        info: MediaCodec.BufferInfo,
        channels: Int,
        target: Int,
        pcmEncoding: Int,
        out: ByteArrayOutputStream,
        skipFrames: Int = 0,
    ) {
        buf.position(info.offset)
        buf.limit(info.offset + info.size)
        val ch = if (channels <= 0) 1 else channels
        if (pcmEncoding == 4) { // ENCODING_PCM_FLOAT
            val fb = buf.order(ByteOrder.nativeOrder()).asFloatBuffer()
            val frames = fb.remaining() / ch
            val skip = skipFrames.coerceIn(0, frames)
            fb.position(skip * ch)
            val frame = FloatArray(ch)
            for (f in skip until frames) {
                for (c in 0 until ch) frame[c] = fb.get()
                writeFrame16(out, frame, ch, target)
            }
        } else { // 16-bit PCM
            val sb = buf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
            val frames = sb.remaining() / ch
            val skip = skipFrames.coerceIn(0, frames)
            sb.position(skip * ch)
            val frame = FloatArray(ch)
            for (f in skip until frames) {
                for (c in 0 until ch) frame[c] = sb.get() / 32768f
                writeFrame16(out, frame, ch, target)
            }
        }
    }

    private fun writeFrame16(out: ByteArrayOutputStream, frame: FloatArray, ch: Int, target: Int) {
        if (target == 1) {
            var sum = 0f
            for (c in 0 until ch) sum += frame[c]
            putShort(out, sum / ch)
        } else { // stereo
            putShort(out, frame[0])
            putShort(out, if (ch >= 2) frame[1] else frame[0])
        }
    }

    private fun putShort(out: ByteArrayOutputStream, sample: Float) {
        val clamped = if (sample > 1f) 1f else if (sample < -1f) -1f else sample
        val v = (clamped * 32767f).toInt()
        out.write(v and 0xFF)
        out.write((v shr 8) and 0xFF)
    }

    private fun encodeM4a(outPath: String, pcm: ByteArray, sampleRate: Int, channels: Int) {
        File(outPath).parentFile?.mkdirs()
        val encoder = MediaCodec.createEncoderByType(AAC_MIME)
        val muxer = MediaMuxer(outPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerTrack = -1
        var muxerStarted = false
        try {
            val format = MediaFormat.createAudioFormat(AAC_MIME, sampleRate, channels).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 64 * 1024)
            }
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()

            val info = MediaCodec.BufferInfo()
            val bytesPerFrame = channels * 2
            val totalFrames = pcm.size / bytesPerFrame
            var inFrame = 0
            var sawInputEOS = false
            var sawOutputEOS = false

            while (!sawOutputEOS) {
                if (!sawInputEOS) {
                    val inIndex = encoder.dequeueInputBuffer(TIMEOUT_US)
                    if (inIndex >= 0) {
                        val inBuf = encoder.getInputBuffer(inIndex)!!
                        inBuf.clear()
                        val maxFrames = inBuf.remaining() / bytesPerFrame
                        val framesThis = minOf(maxFrames, totalFrames - inFrame)
                        if (framesThis <= 0) {
                            val ptsUs = (inFrame.toLong() * 1_000_000L) / sampleRate
                            encoder.queueInputBuffer(inIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            sawInputEOS = true
                        } else {
                            val byteLen = framesThis * bytesPerFrame
                            inBuf.put(pcm, inFrame * bytesPerFrame, byteLen)
                            val ptsUs = (inFrame.toLong() * 1_000_000L) / sampleRate
                            encoder.queueInputBuffer(inIndex, 0, byteLen, ptsUs, 0)
                            inFrame += framesThis
                        }
                    }
                }

                val outIndex = encoder.dequeueOutputBuffer(info, TIMEOUT_US)
                if (outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    muxerTrack = muxer.addTrack(encoder.outputFormat)
                    muxer.start()
                    muxerStarted = true
                } else if (outIndex >= 0) {
                    val outBuf = encoder.getOutputBuffer(outIndex)
                    // Codec-config bytes go to the muxer via addTrack's format, not as a sample.
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                    if (info.size > 0 && muxerStarted && outBuf != null) {
                        outBuf.position(info.offset)
                        outBuf.limit(info.offset + info.size)
                        muxer.writeSampleData(muxerTrack, outBuf, info)
                    }
                    encoder.releaseOutputBuffer(outIndex, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) sawOutputEOS = true
                }
            }
        } finally {
            try { encoder.stop() } catch (_: Exception) {}
            try { encoder.release() } catch (_: Exception) {}
            try { if (muxerStarted) muxer.stop() } catch (_: Exception) {}
            try { muxer.release() } catch (_: Exception) {}
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) return i
        }
        return -1
    }
}
