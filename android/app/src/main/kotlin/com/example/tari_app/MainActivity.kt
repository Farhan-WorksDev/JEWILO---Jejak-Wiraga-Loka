package com.example.tari_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarker
import com.google.mediapipe.tasks.vision.holisticlandmarker.HolisticLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.belajarbareng/mediapipe_holistic"
    private var holisticLandmarker: HolisticLandmarker? = null
    private var lastTimestampMs: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val modelPath = call.argument<String>("modelPath") ?: ""
                        try {
                            initLandmarker(modelPath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INIT_FAILED", e.message ?: "unknown", null)
                        }
                    }
                    "extract" -> {
                        val width = call.argument<Int>("width") ?: 0
                        val height = call.argument<Int>("height") ?: 0
                        val yPlane = call.argument<ByteArray>("yPlane")
                        val uPlane = call.argument<ByteArray>("uPlane")
                        val vPlane = call.argument<ByteArray>("vPlane")
                        val yRowStride = call.argument<Int>("yRowStride") ?: width
                        val uvRowStride = call.argument<Int>("uvRowStride") ?: width / 2
                        val uvPixelStride = call.argument<Int>("uvPixelStride") ?: 2
                        val rotation = call.argument<Int>("rotation") ?: 0

                        if (yPlane == null || uPlane == null || vPlane == null) {
                            result.error("INVALID_IMAGE", "Plane buffers null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val features = extractLandmarks(
                                width, height, yPlane, uPlane, vPlane,
                                yRowStride, uvRowStride, uvPixelStride, rotation
                            )
                            result.success(features)
                        } catch (e: Exception) {
                            result.error("EXTRACT_FAILED", e.message ?: "unknown", null)
                        }
                    }
                    "dispose" -> {
                        holisticLandmarker?.close()
                        holisticLandmarker = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initLandmarker(modelPath: String) {
        val baseOptions = BaseOptions.builder().setModelAssetPath(modelPath).build()
        val options = HolisticLandmarker.HolisticLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.VIDEO)
            .setMinFaceDetectionConfidence(0.5f)
            .setMinFaceSuppressionThreshold(0.5f)
            .setMinFacePresenceConfidence(0.5f)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPoseSuppressionThreshold(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinHandLandmarksConfidence(0.5f)
            .setOutputFaceBlendshapes(false)
            .build()
        holisticLandmarker = HolisticLandmarker.createFromOptions(this, options)
        lastTimestampMs = 0
    }

    private fun extractLandmarks(
        width: Int, height: Int,
        yPlane: ByteArray, uPlane: ByteArray, vPlane: ByteArray,
        yRowStride: Int, uvRowStride: Int, uvPixelStride: Int,
        rotation: Int
    ): List<Double> {
        val bitmap = yuv420ToBitmap(
            width, height, yPlane, uPlane, vPlane,
            yRowStride, uvRowStride, uvPixelStride
        )
        val rotated: Bitmap = if (rotation != 0) {
            val matrix = Matrix().apply { postRotate(rotation.toFloat()) }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                .also { if (it != bitmap) bitmap.recycle() }
        } else bitmap
        val mpImage: MPImage = BitmapImageBuilder(rotated).build()
        val ts = System.currentTimeMillis()
        if (ts <= lastTimestampMs) lastTimestampMs += 1 else lastTimestampMs = ts
        val result: HolisticLandmarkerResult? =
            holisticLandmarker?.detectForVideo(mpImage, lastTimestampMs)
        if (rotated != bitmap) rotated.recycle()
        bitmap.recycle()
        val poseLandmarks = result?.poseLandmarks()
        if (poseLandmarks == null || poseLandmarks.size < 33) return emptyList()
        val features = ArrayList<Double>(300)
        for (i in 0 until 33) {
            val lm = poseLandmarks[i]
            features.add(lm.x().toDouble())
            features.add(lm.y().toDouble())
            features.add(lm.z().toDouble())
            val vis = try {
                if (lm.visibility().isPresent) lm.visibility().get().toDouble() else 0.0
            } catch (_: Exception) { 0.0 }
            features.add(vis)
        }
        appendHand(features, result?.leftHandLandmarks())
        appendHand(features, result?.rightHandLandmarks())
        while (features.size < 300) features.add(0.0)
        return features.take(300)
    }

    private fun appendHand(features: ArrayList<Double>, hand: List<NormalizedLandmark>?) {
        if (hand != null && hand.size >= 21) {
            for (i in 0 until 21) {
                val lm = hand[i]
                features.add(lm.x().toDouble())
                features.add(lm.y().toDouble())
                features.add(lm.z().toDouble())
                features.add(1.0)
            }
        } else {
            repeat(84) { features.add(0.0) }
        }
    }

    private fun yuv420ToBitmap(
        width: Int, height: Int,
        yPlane: ByteArray, uPlane: ByteArray, vPlane: ByteArray,
        yRowStride: Int, uvRowStride: Int, uvPixelStride: Int
    ): Bitmap {
        val ySize = width * height
        val nv21 = ByteArray(ySize + 2 * (width * height / 4))
        var yOffset = 0
        for (row in 0 until height) {
            System.arraycopy(yPlane, row * yRowStride, nv21, yOffset, width)
            yOffset += width
        }
        var uvOffset = ySize
        val chromaHeight = height / 2
        val chromaWidth = width / 2
        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val uvIndex = row * uvRowStride + col * uvPixelStride
                nv21[uvOffset++] = if (uvIndex < vPlane.size) vPlane[uvIndex] else 0
                nv21[uvOffset++] = if (uvIndex < uPlane.size) uPlane[uvIndex] else 0
            }
        }
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 80, out)
        val bytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    }
}
