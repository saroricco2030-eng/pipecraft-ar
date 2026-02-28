package com.athvacr.pipecraft_ar

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "pipecraft/ar_measure"
        private const val AR_MEASURE_REQUEST = 1001
    }

    // AtomicReference로 스레드 안전하게 pendingResult 관리
    private val pendingResult = AtomicReference<MethodChannel.Result?>(null)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDistance" -> {
                        // 이전 요청이 미완료 상태면 취소 처리
                        pendingResult.getAndSet(result)?.success(null)
                        val intent = Intent(this, ArMeasureActivity::class.java)
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, AR_MEASURE_REQUEST)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == AR_MEASURE_REQUEST) {
            val result = pendingResult.getAndSet(null) ?: return

            if (resultCode == Activity.RESULT_OK && data != null
                && data.hasExtra(ArMeasureActivity.EXTRA_DISTANCE_MM)) {
                val distance = data.getDoubleExtra(ArMeasureActivity.EXTRA_DISTANCE_MM, -1.0)
                if (distance >= 0) {
                    result.success(distance)
                } else {
                    result.error("NO_DATA", "거리 데이터를 받지 못했습니다", null)
                }
            } else {
                result.success(null)
            }
        }
    }
}
