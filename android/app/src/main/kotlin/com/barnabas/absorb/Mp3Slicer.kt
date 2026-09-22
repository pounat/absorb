package com.barnabas.absorb

import android.content.Context
import android.net.Uri
import android.util.Log
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

/**
 * Cuts a byte-exact slice out of an MP3 by counting frame headers from the start
 * of the file.
 *
 * MediaExtractor can't be asked to do this. An MP3 carries no seek table, so its
 * seek is a bitrate guess that lands tens of seconds out on a variable-bitrate
 * file - which most podcasts are - and it then reports the time it was asked for
 * rather than the time it reached, so the drift is invisible from the outside.
 * Frame headers each carry their own size, so walking them is exact, and only the
 * 4-byte headers have to be read: the frame bodies are skipped until the window
 * we actually want. Scanning half an hour of audio that way costs a sequential
 * read, not a decode.
 *
 * An MP4/M4B has a real sample table and seeks exactly, so books never come
 * through here.
 */
internal object Mp3Slicer {
    private const val TAG = "AbsorbTranscribe"

    /** Audio kept ahead of the requested time, to give the decoder a run-up. */
    private const val PRE_ROLL_S = 0.5

    /** How far into the file to look for the first frame before giving up. */
    private const val SYNC_SEARCH_BYTES = 128 * 1024

    /** Frames to walk before deciding the file isn't what its header claims. */
    private const val MAX_FRAMES = 5_000_000

    // Layer III bitrates in kbps. Index 0 is "free format" and 15 is invalid;
    // both are left as 0 so the frame is rejected rather than guessed at.
    private val BITRATES_V1 =
        intArrayOf(0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0)
    private val BITRATES_V2 =
        intArrayOf(0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0)
    private val RATES_V1 = intArrayOf(44100, 48000, 32000, 0)
    private val RATES_V2 = intArrayOf(22050, 24000, 16000, 0)
    private val RATES_V25 = intArrayOf(11025, 12000, 8000, 0)

    /**
     * A cut-down copy of the source. [startSeconds] is where the caller's
     * requested time sits inside it, and [temp] is the caller's to delete.
     */
    class Prepared(val path: String, val startSeconds: Double, val temp: File)

    private class Frame(val length: Int, val durationS: Double)

    /**
     * Slice [source] down to the frames covering [startSeconds] and the
     * [durationSeconds] after it. Returns null when the source isn't a Layer III
     * MP3 that walks cleanly, in which case the caller should carry on with the
     * original source untouched.
     */
    fun prepare(
        context: Context,
        source: String,
        startSeconds: Double,
        durationSeconds: Double,
    ): Prepared? {
        // The start of the file needs no help: a seek to ~0 lands on ~0.
        if (startSeconds <= PRE_ROLL_S) return null
        val temp = try {
            File.createTempFile("mp3slice", ".mp3", context.cacheDir)
        } catch (e: Exception) {
            Log.d(TAG, "mp3 slice skipped, no temp file: ${e.message}")
            return null
        }
        val prepared = try {
            scan(context, source, startSeconds, durationSeconds, temp)
        } catch (e: Exception) {
            Log.d(TAG, "mp3 slice skipped: ${e.message}")
            null
        }
        if (prepared == null) temp.delete()
        return prepared
    }

    private fun scan(
        context: Context,
        source: String,
        startSeconds: Double,
        durationSeconds: Double,
        temp: File,
    ): Prepared? {
        val raw = openStream(context, source) ?: return null
        val input = BufferedInputStream(raw, 64 * 1024)
        var out: FileOutputStream? = null
        try {
            if (!skipId3(input)) return null

            val header = ByteArray(4)
            if (!findFirstFrame(input, header)) return null

            val copyBuf = ByteArray(8192)
            val wantStart = startSeconds - PRE_ROLL_S
            val wantEnd = startSeconds + durationSeconds + PRE_ROLL_S
            var timeS = 0.0
            var sliceStartS = -1.0
            var haveHeader = true
            var frames = 0

            while (frames++ < MAX_FRAMES) {
                if (!haveHeader && !readFully(input, header, 4)) break
                haveHeader = false
                // Files often end with an ID3v1 or APE trailer, which is not a
                // frame. Once the slice is underway that just means the audio
                // ran out; before then, it means this isn't a file we can walk.
                val frame = parseHeader(header)
                if (frame == null || frame.length <= 4) {
                    if (out != null) break
                    return null
                }
                val body = frame.length - 4

                if (sliceStartS < 0 && timeS + frame.durationS > wantStart) {
                    sliceStartS = timeS
                    out = FileOutputStream(temp)
                }
                val sink = out
                if (sink != null) {
                    sink.write(header)
                    if (!copyFully(input, sink, body, copyBuf)) break
                } else if (!skipFully(input, body.toLong())) {
                    break
                }
                timeS += frame.durationS
                if (sink != null && timeS >= wantEnd) break
            }

            out?.flush()
            // Never reached the window - the file ended early, or it isn't as
            // long as the caller thinks. Leave the old path to deal with it.
            if (out == null || sliceStartS < 0) return null

            val offset = startSeconds - sliceStartS
            Log.d(
                TAG,
                "mp3 slice: want=${"%.1f".format(startSeconds)}s " +
                    "slice=${"%.1f".format(sliceStartS)}s offset=${"%.2f".format(offset)}s " +
                    "frames=$frames bytes=${temp.length()}",
            )
            return Prepared(temp.absolutePath, offset, temp)
        } finally {
            try { out?.close() } catch (_: Exception) {}
            try { input.close() } catch (_: Exception) {}
        }
    }

    private fun openStream(context: Context, source: String): InputStream? = when {
        source.startsWith("content://") ->
            context.contentResolver.openInputStream(Uri.parse(source))
        // A streamed book is an http(s) URL - nothing to walk locally.
        source.startsWith("http") -> null
        else -> File(source).takeIf { it.isFile }?.inputStream()
    }

    /** Step over an ID3v2 tag if the file opens with one. */
    private fun skipId3(input: BufferedInputStream): Boolean {
        input.mark(16)
        val head = ByteArray(10)
        if (!readFully(input, head, 10)) return false
        val isId3 = head[0] == 'I'.code.toByte() &&
            head[1] == 'D'.code.toByte() &&
            head[2] == '3'.code.toByte()
        if (!isId3) {
            input.reset() // those 10 bytes were audio
            return true
        }
        // Syncsafe: seven bits per byte, top bit always clear.
        val size = ((head[6].toInt() and 0x7F) shl 21) or
            ((head[7].toInt() and 0x7F) shl 14) or
            ((head[8].toInt() and 0x7F) shl 7) or
            (head[9].toInt() and 0x7F)
        val footer = if ((head[5].toInt() and 0x10) != 0) 10L else 0L
        return skipFully(input, size.toLong() + footer)
    }

    /**
     * Leave [input] just past the first frame header, with that header in
     * [header]. A lone valid-looking header can turn up in leftover junk, so a
     * candidate only counts when the frame it describes is followed by another
     * valid header.
     */
    private fun findFirstFrame(input: BufferedInputStream, header: ByteArray): Boolean {
        if (!readFully(input, header, 4)) return false
        var searched = 0
        while (searched < SYNC_SEARCH_BYTES) {
            val frame = parseHeader(header)
            if (frame != null && nextHeaderFollows(input, frame)) return true
            // Shift the window on by a byte and try again.
            header[0] = header[1]
            header[1] = header[2]
            header[2] = header[3]
            val next = input.read()
            if (next < 0) return false
            header[3] = next.toByte()
            searched++
        }
        return false
    }

    /** Peek past this frame to check another header starts where it should. */
    private fun nextHeaderFollows(input: BufferedInputStream, frame: Frame): Boolean {
        val body = frame.length - 4
        if (body <= 0) return false
        input.mark(frame.length + 8)
        return try {
            if (!skipFully(input, body.toLong())) return false
            val peek = ByteArray(4)
            if (!readFully(input, peek, 4)) return false
            parseHeader(peek) != null
        } catch (_: Exception) {
            false
        } finally {
            try { input.reset() } catch (_: Exception) {}
        }
    }

    private fun parseHeader(h: ByteArray): Frame? {
        if ((h[0].toInt() and 0xFF) != 0xFF) return null
        val b1 = h[1].toInt() and 0xFF
        if ((b1 and 0xE0) != 0xE0) return null
        val version = (b1 shr 3) and 0x03 // 0 = MPEG2.5, 1 = reserved, 2 = MPEG2, 3 = MPEG1
        val layer = (b1 shr 1) and 0x03   // 1 = Layer III
        if (version == 1 || layer != 1) return null
        val b2 = h[2].toInt() and 0xFF
        val bitrate = (if (version == 3) BITRATES_V1 else BITRATES_V2)[(b2 shr 4) and 0x0F]
        val rateIndex = (b2 shr 2) and 0x03
        val rate = when (version) {
            3 -> RATES_V1[rateIndex]
            2 -> RATES_V2[rateIndex]
            else -> RATES_V25[rateIndex]
        }
        if (bitrate <= 0 || rate <= 0) return null
        val padding = (b2 shr 1) and 0x01
        val samples = if (version == 3) 1152 else 576
        val length = samples / 8 * bitrate * 1000 / rate + padding
        if (length < 24) return null
        return Frame(length, samples.toDouble() / rate)
    }

    private fun readFully(input: InputStream, buf: ByteArray, len: Int): Boolean {
        var off = 0
        while (off < len) {
            val n = input.read(buf, off, len - off)
            if (n < 0) return false
            off += n
        }
        return true
    }

    private fun skipFully(input: InputStream, count: Long): Boolean {
        var left = count
        while (left > 0) {
            val n = input.skip(left)
            if (n > 0) {
                left -= n
            } else {
                // skip() is allowed to do nothing; read a byte to make progress.
                if (input.read() < 0) return false
                left--
            }
        }
        return true
    }

    private fun copyFully(
        input: InputStream,
        out: OutputStream,
        count: Int,
        buf: ByteArray,
    ): Boolean {
        var left = count
        while (left > 0) {
            val n = input.read(buf, 0, minOf(left, buf.size))
            if (n < 0) return false
            out.write(buf, 0, n)
            left -= n
        }
        return true
    }
}
