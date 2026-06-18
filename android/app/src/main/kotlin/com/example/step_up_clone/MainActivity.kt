package com.example.step_up_clone

import android.util.Log
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), SensorEventListener {

    private val TAG = "STEP_DEBUG_ANDROID"
    private lateinit var sensorManager: SensorManager
    private var stepCounterSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        if (stepCounterSensor == null) {
            Log.e(TAG, "❌ FAILURE: TYPE_STEP_COUNTER sensor not detected on this device!")
        } else {
            Log.d(TAG, "✅ SUCCESS: Step counter hardware hook detected.")
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "step_counter_channel")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "🔌 Flutter app connected to stream channel.")
                    eventSink = events
                    startSensor()
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "🔌 Flutter disconnected from stream channel.")
                    stopSensor()
                    eventSink = null
                }
            })
    }

    private fun startSensor() {
        stepCounterSensor?.let {
            val registered = sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            Log.d(TAG, "📡 Hardware listener status: $registered")
        }
    }

    private fun stopSensor() {
        Log.d(TAG, "🛑 Stopping hardware listener.")
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        
        val totalStepsSinceBoot = event.values[0].toInt()
        
        // HIGH VISIBILITY LOG
        Log.d(TAG, "========================================")
        Log.d(TAG, "📱 HARDWARE LAYER READOUT: $totalStepsSinceBoot")
        Log.d(TAG, "========================================")
        
        eventSink?.success(totalStepsSinceBoot)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}