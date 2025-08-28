package com.example.vibealarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import java.io.File

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "vibealarm_alarm_channel"
        const val NOTIFICATION_ID = 1001
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_MESSAGE = "alarm_message"
        const val EXTRA_ALARM_TIME = "alarm_time"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm received: ${intent.action}")
        
        when (intent.action) {
            "com.example.vibealarm.ALARM_TRIGGER" -> {
                val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "unknown"
                val alarmMessage = intent.getStringExtra(EXTRA_ALARM_MESSAGE) ?: "Time to wake up!"
                val alarmTime = intent.getStringExtra(EXTRA_ALARM_TIME) ?: ""
                
                Log.d("AlarmReceiver", "Processing alarm: ID=$alarmId, Message=$alarmMessage, Time=$alarmTime")
                
                // Acquire WAKE_LOCK to keep device awake
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "VibeAlarm:AlarmWakeLock"
                )
                wakeLock.acquire(10 * 60 * 1000L) // 10 minutes
                
                try {
                    // Start foreground service to keep alarm alive
                    AlarmForegroundService.startService(context)
                    
                    // Create notification channel for Android O and above
                    createNotificationChannel(context)
                    
                    // Show notification
                    showAlarmNotification(context, alarmId, alarmMessage, alarmTime)
                    
                    // Start alarm sound and vibration
                    startAlarmSound(context, intent)
                    startVibration(context)
                    
                    // Launch Flutter app to show alarm UI
                    launchFlutterApp(context, intent)
                    
                } finally {
                    // Release wake lock after a delay to ensure alarm is processed
                    wakeLock.release()
                }
            }
            
            "com.example.vibealarm.STOP_ALARM" -> {
                val alarmId = intent.getStringExtra("alarm_id")
                Log.d("AlarmReceiver", "Stopping alarm: $alarmId")
                
                // Stop alarm sound and vibration
                AlarmSoundManager.stopAlarm()
                
                // Cancel notification
                val notificationManager = NotificationManagerCompat.from(context)
                notificationManager.cancel(NOTIFICATION_ID)
            }
        }
    }
    
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "VibeAlarm Alarms"
            val descriptionText = "Alarm notifications for VibeAlarm"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager: NotificationManager = 
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun showAlarmNotification(context: Context, alarmId: String, message: String, time: String) {
        // Create intent to launch MainActivity with alarm data (same as launchFlutterApp)
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("alarm_triggered", true)
            putExtra("alarm_id", alarmId)
            putExtra("alarm_message", message)
            putExtra("alarm_time", time)
            putExtra("show_alarm_screen", true)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("VibeAlarm")
            .setContentText(message)
            .setSubText("Scheduled for: $time")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(true)
            .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
            .setContentIntent(pendingIntent)
            .addAction(
                R.mipmap.ic_launcher,
                "STOP ALARM",
                createStopAlarmPendingIntent(context, alarmId)
            )
        
        with(NotificationManagerCompat.from(context)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == 
                    android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    notify(NOTIFICATION_ID, builder.build())
                }
            } else {
                notify(NOTIFICATION_ID, builder.build())
            }
        }
    }
    
    private fun createStopAlarmPendingIntent(context: Context, alarmId: String): PendingIntent {
        val stopIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.example.vibealarm.STOP_ALARM"
            putExtra("alarm_id", alarmId)
        }
        
        return PendingIntent.getBroadcast(
            context,
            alarmId.hashCode() + 1000, // Different request code
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    private fun startAlarmSound(context: Context, intent: Intent) {
        try {
            // Try to use custom audio file first
            val customAudioPath = intent.getStringExtra("custom_audio_path")
            var audioUri: Uri? = null
            
            if (!customAudioPath.isNullOrEmpty()) {
                try {
                    val customFile = File(customAudioPath)
                    if (customFile.exists()) {
                        audioUri = Uri.fromFile(customFile)
                        Log.d("AlarmReceiver", "Using custom audio: $customAudioPath")
                    }
                } catch (e: Exception) {
                    Log.e("AlarmReceiver", "Error with custom audio: ${e.message}")
                }
            }
            
            // Fallback to default alarm sound
            if (audioUri == null) {
                audioUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                Log.d("AlarmReceiver", "Using default alarm sound")
            }
            
            if (audioUri != null) {


                
                val mediaPlayer = MediaPlayer()
                mediaPlayer.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mediaPlayer.setDataSource(context, audioUri)
                mediaPlayer.isLooping = true
                mediaPlayer.prepare()
                mediaPlayer.start()
                
                // Store MediaPlayer reference for stopping later
                AlarmSoundManager.setMediaPlayer(mediaPlayer)
                Log.d("AlarmReceiver", "Alarm sound started successfully")
            }
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error starting alarm sound: ${e.message}")
        }
    }
    
    private fun startVibration(context: Context) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            if (vibrator.hasVibrator()) {
                val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val effect = VibrationEffect.createWaveform(pattern, 0)
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(pattern, 0)
                }
                
                // Store Vibrator reference for stopping later
                AlarmSoundManager.setVibrator(vibrator)
            }
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error starting vibration: ${e.message}")
        }
    }
    
    private fun launchFlutterApp(context: Context, intent: Intent) {
        try {
            // Get the alarm data from the current intent
            val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "unknown"
            val alarmMessage = intent.getStringExtra(EXTRA_ALARM_MESSAGE) ?: "Time to wake up!"
            val alarmTime = intent.getStringExtra(EXTRA_ALARM_TIME) ?: ""
            
            Log.d("AlarmReceiver", "Launching Flutter app with alarm data: ID=$alarmId, Message=$alarmMessage, Time=$alarmTime")
            
            // Create intent to launch MainActivity with alarm data
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("alarm_triggered", true)
                putExtra("alarm_id", alarmId)
                putExtra("alarm_message", alarmMessage)
                putExtra("alarm_time", alarmTime)
                putExtra("show_alarm_screen", true)
            }
            
            context.startActivity(launchIntent)
            Log.d("AlarmReceiver", "Flutter app launched successfully with alarm data")
            
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error launching Flutter app: ${e.message}")
        }
    }
} 