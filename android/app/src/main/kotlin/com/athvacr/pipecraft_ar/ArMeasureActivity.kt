package com.athvacr.pipecraft_ar

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.Surface
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.google.ar.core.Anchor
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.HitResult
import com.google.ar.core.InstantPlacementPoint
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.UnavailableApkTooOldException
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableSdkTooOldException
import com.athvacr.pipecraft_ar.rendering.BackgroundRenderer
import com.athvacr.pipecraft_ar.rendering.PointLineRenderer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.sqrt

class ArMeasureActivity : Activity(), GLSurfaceView.Renderer {

    companion object {
        private const val TAG = "ArMeasureActivity"
        const val EXTRA_DISTANCE_MM = "distance_mm"
        private const val APPROXIMATE_DISTANCE_M = 2.0f
        // UI 업데이트 throttle: onDrawFrame에서 매 프레임 runOnUiThread 하면
        // UI 스레드에 초당 60회 post됨. 100ms = 10fps면 사용자 인지로 충분.
        private const val UI_UPDATE_THROTTLE_MS = 100L

        // 렌더링 컬러 — 매 프레임 새로 할당하지 않도록 companion 상수로 hoist
        private val ANCHOR_COLOR = floatArrayOf(1f, 0.62f, 0.04f, 1f)
        private val FIRST_POINT_COLOR = floatArrayOf(0.22f, 0.74f, 0.97f, 1f)
        private val LINE_COLOR = floatArrayOf(0.22f, 0.74f, 0.97f, 1f)
    }

    // 매 프레임 재사용 — onDrawFrame에서 GC 압박 줄이기
    private val anchorSnapshot = ArrayList<Anchor>(16)
    private val positions = ArrayList<FloatArray>(16)
    private val segmentDists = ArrayList<Double>(16)

    // ── i18n Strings (Flutter에서 Intent로 주입) ─────
    private data class ArStrings(
        val scanHint: String,
        val trackingLost: String,
        val planeNotDetected: String,
        val tapFirstPoint: String,
        val tapSecondPoint: String,
        val multiPointTemplate: String,
        val noSurface: String,
        val btnUndo: String,
        val btnReset: String,
        val btnConfirm: String,
        val totalPrefix: String,
        val segmentTemplate: String,
        val errorDeviceUnsupported: String,
        val errorApkTooOld: String,
        val errorSdkTooOld: String,
        val errorSessionInit: String,
        val errorCameraUnavailable: String,
    ) {
        fun multiPoint(count: Int) =
            multiPointTemplate.replace("{count}", count.toString())

        fun segment(index: Int, distance: String) = segmentTemplate
            .replace("{index}", index.toString())
            .replace("{distance}", distance)
    }

    // ── Colors (Flutter에서 Intent로 주입) ────────────
    private data class ArColors(
        val primary: Int,
        val secondary: Int,
        val onPrimary: Int,
    )

    private lateinit var strings: ArStrings
    private lateinit var colors: ArColors

    private lateinit var glSurfaceView: GLSurfaceView
    private lateinit var statusText: TextView
    private lateinit var distanceText: TextView
    private lateinit var confirmButton: TextView
    private lateinit var resetButton: TextView
    private lateinit var undoButton: TextView
    private lateinit var buttonContainer: LinearLayout
    private lateinit var segmentInfoText: TextView

    private var arSession: Session? = null
    private var installRequested = false

    private val backgroundRenderer = BackgroundRenderer()
    private val pointLineRenderer = PointLineRenderer()

    // anchors는 GL 스레드(onDrawFrame, handleTap)와 UI 스레드(undo, reset)에서 접근
    private val anchorLock = Any()
    private val anchors = mutableListOf<Anchor>()

    @Volatile private var measuredDistanceMm: Double? = null
    @Volatile private var touchX = 0f
    @Volatile private var touchY = 0f
    @Volatile private var hasPendingTap = false
    @Volatile private var planeDetected = false

    private val viewMatrix = FloatArray(16)
    private val projMatrix = FloatArray(16)

    private var cameraTextureId = -1
    private var sessionNeedsTextureName = false

    private var viewportWidth = 0
    private var viewportHeight = 0
    private var viewportChanged = false

    private var lastStatusUpdate = 0L
    private var lastDistanceUpdate = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        strings = readStrings(intent)
        colors = readColors(intent)

        val root = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        glSurfaceView = GLSurfaceView(this).apply {
            preserveEGLContextOnPause = true
            setEGLContextClientVersion(2)
            setEGLConfigChooser(8, 8, 8, 8, 16, 0)
            setRenderer(this@ArMeasureActivity)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        root.addView(glSurfaceView)

        val overlay = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        statusText = TextView(this).apply {
            text = strings.scanHint
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(60), dp(24), 0)
            setShadowLayer(4f, 0f, 0f, Color.BLACK)
        }
        overlay.addView(statusText, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        overlay.addView(View(this), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
        ))

        distanceText = TextView(this).apply {
            text = ""
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 40f)
            gravity = Gravity.CENTER
            setShadowLayer(6f, 0f, 0f, Color.BLACK)
            visibility = View.GONE
        }
        overlay.addView(distanceText, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        overlay.addView(View(this), LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
        ))

        segmentInfoText = TextView(this).apply {
            text = ""
            setTextColor(Color.parseColor("#CCCCCC"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            setShadowLayer(4f, 0f, 0f, Color.BLACK)
            setPadding(dp(16), dp(4), dp(16), dp(8))
            visibility = View.GONE
        }
        overlay.addView(segmentInfoText, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        buttonContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(8), dp(16), dp(32))
            visibility = View.GONE
        }

        // CLAUDE.md 터치 기준: 일반 버튼 56dp. 장갑 환경 대응.
        val btnHeight = dp(56)

        undoButton = makeButton(strings.btnUndo, colors.secondary, colors.onPrimary).apply {
            setOnClickListener { undoLastPoint() }
        }
        buttonContainer.addView(undoButton, LinearLayout.LayoutParams(
            0, btnHeight, 1f
        ).apply { setMargins(0, 0, dp(6), 0) })

        resetButton = makeButton(strings.btnReset, colors.secondary, colors.onPrimary).apply {
            setOnClickListener { resetMeasurement() }
        }
        buttonContainer.addView(resetButton, LinearLayout.LayoutParams(
            0, btnHeight, 1f
        ).apply { setMargins(dp(6), 0, dp(6), 0) })

        confirmButton = makeButton(strings.btnConfirm, colors.primary, colors.onPrimary).apply {
            setOnClickListener { confirmMeasurement() }
        }
        buttonContainer.addView(confirmButton, LinearLayout.LayoutParams(
            0, btnHeight, 1.4f
        ).apply { setMargins(dp(6), 0, 0, 0) })

        overlay.addView(buttonContainer, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        root.addView(overlay)

        glSurfaceView.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_UP) {
                touchX = event.x
                touchY = event.y
                hasPendingTap = true
            }
            true
        }

        setContentView(root)
    }

    private fun readStrings(intent: Intent): ArStrings {
        fun s(k: String, fallback: String) =
            intent.getStringExtra("str_$k") ?: fallback
        return ArStrings(
            scanHint = s("scanHint", "Slowly move the camera to scan the area"),
            trackingLost = s("trackingLost", "Tracking…"),
            planeNotDetected = s("planeNotDetected", "Scan a floor or wall"),
            tapFirstPoint = s("tapFirstPoint", "Tap a start point"),
            tapSecondPoint = s("tapSecondPoint", "Tap the second point"),
            multiPointTemplate = s("multiPointTemplate", "Point {count} · tap to add more"),
            noSurface = s("noSurface", "No surface at tap"),
            btnUndo = s("btnUndo", "Undo"),
            btnReset = s("btnReset", "Reset"),
            btnConfirm = s("btnConfirm", "Confirm"),
            totalPrefix = s("totalPrefix", "Total"),
            segmentTemplate = s("segmentTemplate", "#{index}: {distance}"),
            errorDeviceUnsupported = s("errorDeviceUnsupported", "ARCore unsupported"),
            errorApkTooOld = s("errorApkTooOld", "ARCore needs update"),
            errorSdkTooOld = s("errorSdkTooOld", "App needs update"),
            errorSessionInit = s("errorSessionInit", "Failed to init AR"),
            errorCameraUnavailable = s("errorCameraUnavailable", "Camera unavailable"),
        )
    }

    private fun readColors(intent: Intent): ArColors {
        fun parse(k: String, fallback: String): Int = try {
            Color.parseColor(intent.getStringExtra("col_$k") ?: fallback)
        } catch (_: IllegalArgumentException) {
            Color.parseColor(fallback)
        }
        return ArColors(
            primary = parse("primary", "#FFE8876B"),       // Coral Soft
            secondary = parse("secondary", "#FF424242"),   // neutral dark
            onPrimary = parse("onPrimary", "#FFFFFFFF"),
        )
    }

    // --- Lifecycle ---

    override fun onResume() {
        super.onResume()

        if (arSession == null) {
            try {
                val availability = ArCoreApk.getInstance().requestInstall(this, !installRequested)
                if (availability == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                    installRequested = true
                    return
                }

                arSession = Session(this).apply {
                    val config = Config(this).apply {
                        planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                        depthMode = Config.DepthMode.DISABLED
                        lightEstimationMode = Config.LightEstimationMode.DISABLED
                        updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                        instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
                    }
                    configure(config)
                }
                if (cameraTextureId >= 0) {
                    arSession?.setCameraTextureName(cameraTextureId)
                } else {
                    sessionNeedsTextureName = true
                }
            } catch (e: UnavailableDeviceNotCompatibleException) {
                showToastAndFinish(strings.errorDeviceUnsupported)
                return
            } catch (e: UnavailableApkTooOldException) {
                showToastAndFinish(strings.errorApkTooOld)
                return
            } catch (e: UnavailableSdkTooOldException) {
                showToastAndFinish(strings.errorSdkTooOld)
                return
            } catch (e: Exception) {
                Log.e(TAG, "AR session init failed", e)
                showToastAndFinish(strings.errorSessionInit)
                return
            }
        }

        try {
            arSession?.resume()
        } catch (e: CameraNotAvailableException) {
            showToastAndFinish(strings.errorCameraUnavailable)
            return
        }

        glSurfaceView.onResume()
    }

    override fun onPause() {
        super.onPause()
        glSurfaceView.onPause()
        arSession?.pause()
    }

    override fun onDestroy() {
        super.onDestroy()
        synchronized(anchorLock) {
            for (anchor in anchors) anchor.detach()
            anchors.clear()
        }
        arSession?.close()
        arSession = null
    }

    // --- GLSurfaceView.Renderer (GL 스레드) ---

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        cameraTextureId = backgroundRenderer.createOnGlThread()
        pointLineRenderer.createOnGlThread()
        arSession?.setCameraTextureName(cameraTextureId)
        sessionNeedsTextureName = false
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        viewportWidth = width
        viewportHeight = height
        viewportChanged = true
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)

        val session = arSession ?: return

        if (sessionNeedsTextureName && cameraTextureId >= 0) {
            session.setCameraTextureName(cameraTextureId)
            sessionNeedsTextureName = false
        }

        if (viewportChanged) {
            val displayRotation = getDisplayRotation()
            session.setDisplayGeometry(displayRotation, viewportWidth, viewportHeight)
            viewportChanged = false
        }

        val frame: Frame
        try {
            frame = session.update()
        } catch (e: CameraNotAvailableException) {
            Log.e(TAG, "Camera not available during update", e)
            return
        }

        backgroundRenderer.draw(frame)

        val camera = frame.camera

        // Tracking 유실 시 planeDetected 리셋 → 다음 tracking 복원에서 재검증
        if (camera.trackingState != TrackingState.TRACKING) {
            planeDetected = false
            updateStatus(strings.trackingLost)
            return
        }

        // 매 프레임 평면 존재 재평가 — planeDetected는 과거 상태가 아닌 현재 상태
        val hasPlane = session.getAllTrackables(Plane::class.java).any {
            it.trackingState == TrackingState.TRACKING
        }
        planeDetected = hasPlane

        camera.getViewMatrix(viewMatrix, 0)
        camera.getProjectionMatrix(projMatrix, 0, 0.1f, 100f)

        if (hasPendingTap) {
            hasPendingTap = false
            handleTap(frame)
        }

        // anchor 스냅샷 — 재사용 가능한 멤버 ArrayList
        anchorSnapshot.clear()
        synchronized(anchorLock) {
            anchorSnapshot.addAll(anchors)
        }

        if (anchorSnapshot.isEmpty()) {
            updateStatus(
                if (planeDetected) strings.tapFirstPoint else strings.planeNotDetected
            )
        }

        GLES20.glEnable(GLES20.GL_DEPTH_TEST)

        positions.clear()
        for (anchor in anchorSnapshot) {
            if (anchor.trackingState == TrackingState.TRACKING) {
                val pose = anchor.pose
                // pos FloatArray는 매 프레임 alloc 불가피 (드로우 콜에 넘김)
                val pos = floatArrayOf(pose.tx(), pose.ty(), pose.tz())
                positions.add(pos)
                val color = if (positions.size == 1) FIRST_POINT_COLOR else ANCHOR_COLOR
                pointLineRenderer.drawPoint(pos, viewMatrix, projMatrix, color)
            }
        }

        if (positions.size >= 2) {
            var totalDist = 0.0
            segmentDists.clear()

            for (i in 0 until positions.size - 1) {
                pointLineRenderer.drawLine(
                    positions[i], positions[i + 1], viewMatrix, projMatrix,
                    LINE_COLOR, lineWidth = 24f,
                    screenWidth = viewportWidth, screenHeight = viewportHeight
                )

                val dx = (positions[i][0] - positions[i + 1][0]).toDouble()
                val dy = (positions[i][1] - positions[i + 1][1]).toDouble()
                val dz = (positions[i][2] - positions[i + 1][2]).toDouble()
                val segDist = sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
                segmentDists.add(segDist)
                totalDist += segDist
            }

            measuredDistanceMm = totalDist
            updateDistanceUi(totalDist, segmentDists)
        }
    }

    // --- 탭 처리 (GL 스레드에서 호출) ---

    private fun handleTap(frame: Frame) {
        val hitResults = frame.hitTest(touchX, touchY)
        val bestHit = pickBestHit(hitResults)

        if (bestHit != null) {
            placeAnchor(bestHit.createAnchor())
            return
        }

        try {
            val instantHits = frame.hitTestInstantPlacement(touchX, touchY, APPROXIMATE_DISTANCE_M)
            if (instantHits.isNotEmpty()) {
                placeAnchor(instantHits[0].createAnchor())
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "Instant placement failed", e)
        }

        val size = synchronized(anchorLock) { anchors.size }
        if (size < 2) {
            runOnUiThread { statusText.text = strings.noSurface }
        }
    }

    /**
     * hitTest 결과에서 가장 좋은 hit를 선택.
     * 우선순위: Plane > Point > InstantPlacement
     */
    private fun pickBestHit(hits: List<HitResult>): HitResult? {
        var bestPlane: HitResult? = null
        var bestPoint: HitResult? = null
        var bestInstant: HitResult? = null

        for (hit in hits) {
            val trackable = hit.trackable
            if (trackable.trackingState != TrackingState.TRACKING) continue

            when (trackable) {
                is Plane -> {
                    if (trackable.isPoseInPolygon(hit.hitPose)) {
                        if (bestPlane == null) bestPlane = hit
                    }
                }
                is Point -> {
                    if (bestPoint == null) bestPoint = hit
                }
                is InstantPlacementPoint -> {
                    if (bestInstant == null) bestInstant = hit
                }
            }
        }

        return bestPlane ?: bestPoint ?: bestInstant
    }

    /** GL 스레드에서 호출 — anchorLock 동기화 */
    private fun placeAnchor(anchor: Anchor) {
        val count: Int
        var totalDist = 0.0

        synchronized(anchorLock) {
            anchors.add(anchor)
            count = anchors.size

            if (count >= 2) {
                for (i in 0 until count - 1) {
                    val a = anchors[i].pose
                    val b = anchors[i + 1].pose
                    val dx = (a.tx() - b.tx()).toDouble()
                    val dy = (a.ty() - b.ty()).toDouble()
                    val dz = (a.tz() - b.tz()).toDouble()
                    totalDist += sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
                }
                measuredDistanceMm = totalDist
            }
        }

        when {
            count == 1 -> runOnUiThread { statusText.text = strings.tapSecondPoint }
            count >= 2 -> runOnUiThread {
                statusText.text = strings.multiPoint(count)
                statusText.visibility = View.VISIBLE
                distanceText.text = formatTotal(totalDist, count)
                distanceText.visibility = View.VISIBLE
                buttonContainer.visibility = View.VISIBLE
            }
        }
    }

    // --- 버튼 액션 (UI 스레드) ---

    private fun undoLastPoint() {
        val remaining: Int
        var totalDist = 0.0

        synchronized(anchorLock) {
            if (anchors.isEmpty()) return
            anchors.removeAt(anchors.size - 1).detach()
            remaining = anchors.size

            if (remaining >= 2) {
                for (i in 0 until remaining - 1) {
                    val a = anchors[i].pose
                    val b = anchors[i + 1].pose
                    val dx = (a.tx() - b.tx()).toDouble()
                    val dy = (a.ty() - b.ty()).toDouble()
                    val dz = (a.tz() - b.tz()).toDouble()
                    totalDist += sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
                }
            }
        }

        when {
            remaining == 0 -> {
                measuredDistanceMm = null
                statusText.text = if (planeDetected) strings.tapFirstPoint else strings.planeNotDetected
                statusText.visibility = View.VISIBLE
                distanceText.visibility = View.GONE
                segmentInfoText.visibility = View.GONE
                buttonContainer.visibility = View.GONE
            }
            remaining == 1 -> {
                measuredDistanceMm = null
                statusText.text = strings.tapSecondPoint
                statusText.visibility = View.VISIBLE
                distanceText.visibility = View.GONE
                segmentInfoText.visibility = View.GONE
                buttonContainer.visibility = View.GONE
            }
            else -> {
                measuredDistanceMm = totalDist
                statusText.text = strings.multiPoint(remaining)
                distanceText.text = formatTotal(totalDist, remaining)
                if (remaining == 2) segmentInfoText.visibility = View.GONE
            }
        }
    }

    private fun resetMeasurement() {
        synchronized(anchorLock) {
            for (anchor in anchors) anchor.detach()
            anchors.clear()
        }
        measuredDistanceMm = null

        statusText.text = if (planeDetected) strings.tapFirstPoint else strings.planeNotDetected
        statusText.visibility = View.VISIBLE
        distanceText.visibility = View.GONE
        segmentInfoText.visibility = View.GONE
        buttonContainer.visibility = View.GONE
    }

    private fun confirmMeasurement() {
        val distance = measuredDistanceMm ?: return
        val resultIntent = Intent().apply {
            putExtra(EXTRA_DISTANCE_MM, distance)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        setResult(RESULT_CANCELED)
        super.onBackPressed()
    }

    // --- Helpers ---

    private fun formatTotal(total: Double, pointCount: Int): String {
        val v = String.format("%.0f", total)
        return if (pointCount == 2) "$v mm" else "${strings.totalPrefix} $v mm"
    }

    private fun updateStatus(msg: String) {
        val now = System.currentTimeMillis()
        if (now - lastStatusUpdate < UI_UPDATE_THROTTLE_MS) return
        lastStatusUpdate = now
        runOnUiThread {
            statusText.text = msg
            statusText.visibility = View.VISIBLE
        }
    }

    /** 거리/세그먼트 UI 업데이트 — throttle 적용 (매 프레임 UI 스레드 부하 방지) */
    private fun updateDistanceUi(totalDist: Double, segmentDists: List<Double>) {
        val now = System.currentTimeMillis()
        if (now - lastDistanceUpdate < UI_UPDATE_THROTTLE_MS) return
        lastDistanceUpdate = now

        val count = segmentDists.size + 1
        val totalText = formatTotal(totalDist, count)

        runOnUiThread {
            distanceText.text = totalText
            if (segmentDists.size > 1) {
                val segInfo = segmentDists.mapIndexed { idx, d ->
                    strings.segment(idx + 1, String.format("%.0f", d))
                }.joinToString("  |  ")
                segmentInfoText.text = segInfo
                segmentInfoText.visibility = View.VISIBLE
            } else {
                segmentInfoText.visibility = View.GONE
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getDisplayRotation(): Int {
        val rotation = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            windowManager.defaultDisplay.rotation
        }
        return when (rotation) {
            Surface.ROTATION_0   -> 0
            Surface.ROTATION_90  -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    /** Coral 브랜드 컬러의 둥근 모서리 버튼. */
    private fun makeButton(text: String, bgColor: Int, textColor: Int): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(12).toFloat()
                setColor(bgColor)
            }
            setPadding(dp(16), dp(12), dp(16), dp(12))
        }
    }

    private fun showToastAndFinish(msg: String) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
        finish()
    }
}
