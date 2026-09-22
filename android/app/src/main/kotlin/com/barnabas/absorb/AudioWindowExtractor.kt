package com.barnabas.absorb

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.util.Log
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Decodes a time window of a compressed audio file into the 16kHz mono 16-bit
 * PCM WAV that whisper.cpp requires - using only the platform MediaCodec stack,
 * so no ffmpeg ships in the app. Used by the opt-in bookmark transcription
 * feature. Runs off the main thread (the caller spawns a worker).
 */
object AudioWindowExtractor {
    private const val TAG = "AbsorbTranscribe"
    private const val TARGET_RATE = 16000
    private const val DEQUEUE_TIMEOUT_US = 10_000L

    /** Boxing-free growable float buffer (a 30s 44.1kHz window is ~1.3M floats). */
    private class FloatBuf(initial: Int) {
        var data = FloatArray(initial.coerceAtLeast(1024))
        var size = 0
        fun add(v: Float) {
            if (size == data.size) data = data.copyOf(size * 2)
            data[size++] = v
        }
        operator fun get(i: Int) = data[i]
    }

    fun extractWav(
        context: Context,
        sourcePath: String,
        startSeconds: Double,
        durationSeconds: Double,
        outPath: String,
    ): Boolean {
        // An MP3 can't be seeked accurately (see [Mp3Slicer]), so cut the window
        // out by frame count first and decode that instead. Anything else - an
        // M4B book, a streamed URL - goes straight through untouched.
        val sliced = Mp3Slicer.prepare(context, sourcePath, startSeconds, durationSeconds)
        return try {
            decodeToWav(
                context,
                sliced?.path ?: sourcePath,
                sliced?.startSeconds ?: startSeconds,
                durationSeconds,
                outPath,
            )
        } finally {
            sliced?.temp?.delete()
        }
    }

    private fun decodeToWav(
        context: Context,
        sourcePath: String,
        startSeconds: Double,
        durationSeconds: Double,
        outPath: String,
    ): Boolean {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            // Books in a custom (SAF) download folder are content:// URIs,
            // which only the context overload can open - same as AudioClipExporter.
            if (sourcePath.startsWith("content://")) {
                extractor.setDataSource(context, Uri.parse(sourcePath), null)
            } else {
                extractor.setDataSource(sourcePath)
            }
            val trackIndex = selectAudioTrack(extractor)
            if (trackIndex < 0) {
                Log.e(TAG, "No audio track in $sourcePath")
                return false
            }
            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME) ?: return false
            val srcRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val srcChannels = if (inputFormat.containsKey(MediaFormat.KEY_CHANNEL_COUNT))
                inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT) else 1

            val startUs = (startSeconds * 1_000_000L).toLong()
            val durationUs = (durationSeconds * 1_000_000L).toLong()
            val landedUs = AudioSeek.seekTo(extractor, startUs)
            // Logged every time, not just when it drifts: on an MP3 the landing
            // time is the extractor's own estimate, so "landed == want" here can
            // still mean the audio is somewhere else entirely.
            Log.d(TAG, "seek want=${startUs / 1000}ms landed=${landedUs / 1000}ms mime=$mime")

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(inputFormat, null, null, 0)
            codec.start()

            val info = MediaCodec.BufferInfo()
            var sawInputEOS = false
            var sawOutputEOS = false
            var outRate = srcRate
            var outChannels = srcChannels
            // AudioFormat.ENCODING_PCM_16BIT == 2, ENCODING_PCM_FLOAT == 4
            var pcmEncoding = if (inputFormat.containsKey(MediaFormat.KEY_PCM_ENCODING))
                inputFormat.getInteger(MediaFormat.KEY_PCM_ENCODING) else 2

            val mono = FloatBuf((srcRate * durationSeconds).toInt())
            var collectedUs = 0L

            while (!sawOutputEOS) {
                if (!sawInputEOS) {
                    val inIndex = codec.dequeueInputBuffer(DEQUEUE_TIMEOUT_US)
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

                val outIndex = codec.dequeueOutputBuffer(info, DEQUEUE_TIMEOUT_US)
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
                        // otherwise the window runs early and the bookmarked
                        // moment falls off the end of it (or out of it entirely).
                        val aheadUs = startUs - info.presentationTimeUs
                        val skipFrames =
                            if (aheadUs > 0) (aheadUs * outRate / 1_000_000L).toInt() else 0
                        appendMono(outBuf, info, outChannels, pcmEncoding, mono, skipFrames)
                        collectedUs = mono.size.toLong() * 1_000_000L / outRate
                    }
                    codec.releaseOutputBuffer(outIndex, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) sawOutputEOS = true
                    if (durationUs > 0 && collectedUs >= durationUs) sawOutputEOS = true
                }
            }

            if (mono.size == 0) {
                Log.e(TAG, "No PCM decoded from $sourcePath")
                return false
            }
            val resampled = resampleTo16k(mono, outRate)
            writeWav(outPath, resampled)
            Log.d(TAG, "extractWav ok: ${resampled.size} samples @16k -> $outPath")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "extractWav failed: ${e.message}", e)
            return false
        } finally {
            try { codec?.stop() } catch (_: Exception) {}
            try { codec?.release() } catch (_: Exception) {}
            try { extractor.release() } catch (_: Exception) {}
        }
    }

    private fun selectAudioTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) return i
        }
        return -1
    }

    /**
     * Append decoded frames, downmixing all channels to a single mono float.
     * [skipFrames] drops that many frames off the front, for a buffer that
     * starts before the window the caller asked for.
     */
    private fun appendMono(
        buf: ByteBuffer,
        info: MediaCodec.BufferInfo,
        channels: Int,
        pcmEncoding: Int,
        out: FloatBuf,
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
            for (f in skip until frames) {
                var sum = 0f
                for (c in 0 until ch) sum += fb.get()
                out.add(sum / ch)
            }
        } else { // 16-bit PCM
            val sb = buf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
            val frames = sb.remaining() / ch
            val skip = skipFrames.coerceIn(0, frames)
            sb.position(skip * ch)
            for (f in skip until frames) {
                var sum = 0
                for (c in 0 until ch) sum += sb.get().toInt()
                out.add((sum.toFloat() / ch) / 32768f)
            }
        }
    }

    /**
     * Area-average resampler to 16kHz. Averaging over the source window each
     * output sample spans acts as a crude anti-alias low-pass for downsampling,
     * which is plenty for speech recognition. Passthrough when already 16kHz.
     */
    private fun resampleTo16k(src: FloatBuf, srcRate: Int): FloatArray {
        if (srcRate == TARGET_RATE) return src.data.copyOf(src.size)
        val ratio = srcRate.toDouble() / TARGET_RATE
        val outLen = (src.size / ratio).toInt().coerceAtLeast(1)
        val out = FloatArray(outLen)
        for (n in 0 until outLen) {
            val startIdx = (n * ratio).toInt().coerceIn(0, src.size - 1)
            val endIdx = ((n + 1) * ratio).toInt().coerceIn(startIdx, src.size - 1)
            var sum = 0f
            var count = 0
            var i = startIdx
            while (i <= endIdx) { sum += src[i]; count++; i++ }
            out[n] = if (count > 0) sum / count else src[startIdx]
        }
        return out
    }

    private fun writeWav(path: String, samples: FloatArray) {
        val dataSize = samples.size * 2
        val file = File(path)
        file.parentFile?.mkdirs()
        RandomAccessFile(file, "rw").use { raf ->
            raf.setLength(0)
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray(Charsets.US_ASCII))
            header.putInt(36 + dataSize)
            header.put("WAVE".toByteArray(Charsets.US_ASCII))
            header.put("fmt ".toByteArray(Charsets.US_ASCII))
            header.putInt(16)              // PCM fmt chunk size
            header.putShort(1)             // audio format = PCM
            header.putShort(1)             // channels = mono
            header.putInt(TARGET_RATE)     // sample rate
            header.putInt(TARGET_RATE * 2) // byte rate = rate * channels * bytesPerSample
            header.putShort(2)             // block align = channels * bytesPerSample
            header.putShort(16)            // bits per sample
            header.put("data".toByteArray(Charsets.US_ASCII))
            header.putInt(dataSize)
            raf.write(header.array())

            val pcm = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN)
            for (s in samples) {
                val clamped = if (s > 1f) 1f else if (s < -1f) -1f else s
                pcm.putShort((clamped * 32767f).toInt().toShort())
            }
            raf.write(pcm.array())
        }
    }
}
