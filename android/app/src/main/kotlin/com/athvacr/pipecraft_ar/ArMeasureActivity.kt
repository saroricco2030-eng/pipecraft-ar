package com.athvacr.pipecraft_ar

import android.app.Activity
import android.content.Intent
import android.graphics.Color
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
    }

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

    // ── 스레드 공유 상태 ──
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        // --- Overlay UI ---
        val overlay = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        statusText = TextView(this).apply {
            text = "카메라를 천천히 움직여 주변을 스캔하세요"
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
            setTextColor(Color.parseColor("#BBBBBB"))
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

        undoButton = makeButton("되돌리기", Color.parseColor("#444444")).apply {
            setOnClickListener { undoLastPoint() }
        }
        buttonContainer.addView(undoButton, LinearLayout.LayoutParams(
            0, dp(48), 1f
        ).apply { setMargins(0, 0, dp(6), 0) })

        resetButton = makeButton("초기화", Color.parseColor("#555555")).apply {
            setOnClickListener { resetMeasurement() }
        }
        buttonContainer.addView(resetButton, LinearLayout.LayoutParams(
            0, dp(48), 1f
        ).apply { setMargins(dp(6), 0, dp(6), 0) })

        confirmButton = makeButton("확인", Color.parseColor("#C8102E")).apply {
            setOnClickListener { confirmMeasurement() }
        }
        buttonContainer.addView(confirmButton, LinearLayout.LayoutParams(
            0, dp(48), 1f
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
                        // Instant Placement — 평면 감지 전에도 포인트 배치 가능
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
                showToastAndFinish("이 기기는 ARCore를 지원하지 않습니다")
                return
            } catch (e: UnavailableApkTooOldException) {
                showToastAndFinish("ARCore 업데이트가 필요합니다")
                return
            } catch (e: UnavailableSdkTooOldException) {
                showToastAndFinish("앱 업데이트가 필요합니다")
                return
            } catch (e: Exception) {
                Log.e(TAG, "AR session init failed", e)
                showToastAndFinish("AR 세션 초기화에 실패했습니다")
                return
            }
        }

        try {
            arSession?.resume()
        } catch (e: CameraNotAvailableException) {
            showToastAndFinish("카메라를 사용할 수 없습니다")
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
        if (camera.trackingState != TrackingState.TRACKING) {
            updateStatus("추적 중... 카메라를 천천히 움직여주세요")
            return
        }

        // 평면 감지 여부 확인 → 상태 메시지 업데이트
        if (!planeDetected) {
            val hasPlane = session.getAllTrackables(Plane::class.java).any {
                it.trackingState == TrackingState.TRACKING
            }
            if (hasPlane) {
                planeDetected = true
            }
        }

        camera.getViewMatrix(viewMatrix, 0)
        camera.getProjectionMatrix(projMatrix, 0, 0.1f, 100f)

        // 터치 처리
        if (hasPendingTap) {
            hasPendingTap = false
            handleTap(frame)
        }

        // 앵커 스냅샷 → 렌더링 (동기화 블록 최소화)
        val anchorSnapshot: List<Anchor>
        synchronized(anchorLock) {
            anchorSnapshot = anchors.toList()
        }

        if (anchorSnapshot.isEmpty()) {
            if (planeDetected) {
                updateStatus("측정할 시작점을 터치하세요")
            } else {
                updateStatus("바닥이나 벽을 향해 천천히 스캔하세요")
            }
        }

        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
        val anchorColor = floatArrayOf(1f, 0.62f, 0.04f, 1f)
        val firstPointColor = floatArrayOf(0.22f, 0.74f, 0.97f, 1f)
        val lineColor = floatArrayOf(0.22f, 0.74f, 0.97f, 1f)

        val positions = mutableListOf<FloatArray>()
        for (anchor in anchorSnapshot) {
            if (anchor.trackingState == TrackingState.TRACKING) {
                val pose = anchor.pose
                val pos = floatArrayOf(pose.tx(), pose.ty(), pose.tz())
                positions.add(pos)
                val color = if (positions.size == 1) firstPointColor else anchorColor
                pointLineRenderer.drawPoint(pos, viewMatrix, projMatrix, color)
            }
        }

        // 연속된 포인트 간 라인 그리기 + 거리 계산
        if (positions.size >= 2) {
            var totalDist = 0.0
            val segmentDists = mutableListOf<Double>()

            for (i in 0 until positions.size - 1) {
                pointLineRenderer.drawLine(positions[i], positions[i + 1], viewMatrix, projMatrix, lineColor)

                val dx = (positions[i][0] - positions[i + 1][0]).toDouble()
                val dy = (positions[i][1] - positions[i + 1][1]).toDouble()
                val dz = (positions[i][2] - positions[i + 1][2]).toDouble()
                val segDist = sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
                segmentDists.add(segDist)
                totalDist += segDist
            }

            measuredDistanceMm = totalDist
            runOnUiThread {
                distanceText.text = "합계 ${String.format("%.0f", totalDist)} mm"

                if (segmentDists.size > 1) {
                    val segInfo = segmentDists.mapIndexed { idx, d ->
                        "${idx + 1}구간: ${String.format("%.0f", d)}"
                    }.joinToString("  |  ")
                    segmentInfoText.text = segInfo
                    segmentInfoText.visibility = View.VISIBLE
                } else {
                    segmentInfoText.visibility = View.GONE
                    distanceText.text = "${String.format("%.0f", totalDist)} mm"
                }
            }
        }
    }

    // --- 탭 처리 (GL 스레드에서 호출) ---

    private fun handleTap(frame: Frame) {
        // 1) 일반 hitTest (Plane, Point)
        val hitResults = frame.hitTest(touchX, touchY)
        val bestHit = pickBestHit(hitResults)

        if (bestHit != null) {
            placeAnchor(bestHit.createAnchor())
            return
        }

        // 2) Instant Placement 폴백 — 평면 없어도 배치
        try {
            val instantHits = frame.hitTestInstantPlacement(touchX, touchY, APPROXIMATE_DISTANCE_M)
            if (instantHits.isNotEmpty()) {
                placeAnchor(instantHits[0].createAnchor())
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "Instant placement failed", e)
        }

        // 3) 아무것도 없으면 안내
        val size = synchronized(anchorLock) { anchors.size }
        if (size < 2) {
            runOnUiThread {
                statusText.text = "터치한 곳에 표면이 없습니다. 다른 곳을 터치하세요."
            }
        }
    }

    /**
     * hitTest 결과에서 가장 좋은 hit를 선택한다.
     * 우선순위: Plane > Point (ORIENTED) > Point > InstantPlacement > null
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

    /** GL 스레드에서 호출 — anchorLock 동기화 필요 */
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
            count == 1 -> {
                runOnUiThread {
                    statusText.text = "두 번째 포인트를 터치하세요"
                }
            }
            count >= 2 -> {
                runOnUiThread {
                    statusText.text = "포인트 $count · 터치하여 계속 추가"
                    statusText.visibility = View.VISIBLE

                    if (count == 2) {
                        distanceText.text = "${String.format("%.0f", totalDist)} mm"
                    } else {
                        distanceText.text = "합계 ${String.format("%.0f", totalDist)} mm"
                    }
                    distanceText.visibility = View.VISIBLE
                    buttonContainer.visibility = View.VISIBLE
                }
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
                statusText.text = if (planeDetected) "측정할 시작점을 터치하세요" else "바닥이나 벽을 향해 천천히 스캔하세요"
                statusText.visibility = View.VISIBLE
                distanceText.visibility = View.GONE
                segmentInfoText.visibility = View.GONE
                buttonContainer.visibility = View.GONE
            }
            remaining == 1 -> {
                measuredDistanceMm = null
                statusText.text = "두 번째 포인트를 터치하세요"
                statusText.visibility = View.VISIBLE
                distanceText.visibility = View.GONE
                segmentInfoText.visibility = View.GONE
                buttonContainer.visibility = View.GONE
            }
            else -> {
                measuredDistanceMm = totalDist
                statusText.text = "포인트 $remaining · 터치하여 계속 추가"
                if (remaining == 2) {
                    distanceText.text = "${String.format("%.0f", totalDist)} mm"
                    segmentInfoText.visibility = View.GONE
                } else {
                    distanceText.text = "합계 ${String.format("%.0f", totalDist)} mm"
                }
            }
        }
    }

    private fun resetMeasurement() {
        synchronized(anchorLock) {
            for (anchor in anchors) {
                anchor.detach()
            }
            anchors.clear()
        }
        measuredDistanceMm = null

        statusText.text = if (planeDetected) "측정할 시작점을 터치하세요" else "바닥이나 벽을 향해 천천히 스캔하세요"
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

    private fun updateStatus(msg: String) {
        val now = System.currentTimeMillis()
        if (now - lastStatusUpdate < 300) return
        lastStatusUpdate = now
        runOnUiThread {
            statusText.text = msg
            statusText.visibility = View.VISIBLE
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

    private fun makeButton(text: String, bgColor: Int): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
            setBackgroundColor(bgColor)
            setPadding(dp(16), dp(12), dp(16), dp(12))
        }
    }

    private fun showToastAndFinish(msg: String) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
        finish()
    }
}
