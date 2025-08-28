package com.example.vibealarm

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.util.Log
import android.os.Build
import android.content.Context
import android.app.AlarmManager
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.vibealarm/native_alarm"
    private val EVENT_CHANNEL = "com.example.vibealarm/alarm_events"
    private lateinit var nativeAlarmService: NativeAlarmService
    private var pendingAlarmData: Map<String, String>? = null
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        nativeAlarmService = NativeAlarmService(this)
        
        // Start foreground service to keep alarm system alive
        AlarmForegroundService.startService(this)
        
        // Check for alarm intent when app starts
        intent?.let { handleAlarmIntent(it) }
        
        // Set up method channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarmId = call.argument<String>("alarmId")
                    val triggerTime = call.argument<Long>("triggerTime")
                    val message = call.argument<String>("message")
                    val timeString = call.argument<String>("timeString")
                    val customAudioPath = call.argument<String>("customAudioPath")
                    
                    if (alarmId != null && triggerTime != null && message != null && timeString != null) {
                        val success = nativeAlarmService.scheduleAlarm(alarmId, triggerTime, message, timeString, customAudioPath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    }
                }
                "cancelAlarm" -> {
                    val alarmId = call.argument<String>("alarmId")
                    if (alarmId != null) {
                        val success = nativeAlarmService.cancelAlarm(alarmId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing alarmId", null)
                    }
                }
                "cancelAllAlarms" -> {
                    val success = nativeAlarmService.cancelAllAlarms()
                    result.success(success)
                }
                "isAlarmScheduled" -> {
                    val alarmId = call.argument<String>("alarmId")
                    if (alarmId != null) {
                        val isScheduled = nativeAlarmService.isAlarmScheduled(alarmId)
                        result.success(isScheduled)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing alarmId", null)
                    }
                }
                "stopAlarm" -> {
                    val success = AlarmSoundManager.stopAlarm()
                    result.success(success)
                }
                "initialize" -> {
                    result.success(null)
                }
                "checkPendingAlarm" -> {
                    // Check if there's pending alarm data to show
                    if (pendingAlarmData != null) {
                        result.success(pendingAlarmData)
                        pendingAlarmData = null // Clear after sending
                    } else {
                        result.success(null)
                    }
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        if (!alarmManager.canScheduleExactAlarms()) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.d("MainActivity", "Native alarm method channel configured")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAlarmIntent(intent)
    }

    private fun handleAlarmIntent(intent: Intent) {
        if (intent.getBooleanExtra("alarm_triggered", false) == true) {
            val alarmId = intent.getStringExtra("alarm_id")
            val alarmMessage = intent.getStringExtra("alarm_message")
            val alarmTime = intent.getStringExtra("alarm_time")
            val showAlarmScreen = intent.getBooleanExtra("show_alarm_screen", false)
            
            Log.d("MainActivity", "Handling alarm intent: ID=$alarmId, Message=$alarmMessage, Time=$alarmTime, ShowScreen=$showAlarmScreen")
            
            if (showAlarmScreen && alarmId != null && alarmMessage != null && alarmTime != null) {
                // Send data to Flutter via method channel
                sendAlarmDataToFlutter(alarmId, alarmMessage, alarmTime)
            }
        }
    }
    
    private fun sendAlarmDataToFlutter(alarmId: String, message: String, time: String) {
        try {
            // This will be handled by Flutter when the app is ready
            Log.d("MainActivity", "Alarm data ready for Flutter: ID=$alarmId, Message=$message, Time=$time")
            
            // Store alarm data temporarily for Flutter to access
            pendingAlarmData = mapOf(
                "alarm_id" to alarmId,
                "alarm_message" to message,
                "alarm_time" to time
            )
            
            // Try to send immediately if Flutter is ready
            methodChannel?.invokeMethod("alarmTriggered", pendingAlarmData)
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Error sending alarm data to Flutter: ${e.message}")
        }
    }
}
