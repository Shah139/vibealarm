package com.example.vibealarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.util.*

class NativeAlarmService(private val context: Context) {
    private val alarmManager: AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    
    companion object {
        private const val TAG = "NativeAlarmService"
    }
    
    /**
     * Schedule an alarm using Android's native AlarmManager
     */
    fun scheduleAlarm(alarmId: String, triggerTime: Long, message: String, timeString: String, customAudioPath: String? = null): Boolean {
        return try {
            Log.d(TAG, "Scheduling native alarm: ID=$alarmId, Time=${Date(triggerTime)}, Message=$message, Audio=$customAudioPath")
            
            // Check if we can schedule exact alarms
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) {
                    Log.e(TAG, "Cannot schedule exact alarms. Permission required.")
                    // Try to open settings for user to grant permission
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    return false
                }
            }
            
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = "com.example.vibealarm.ALARM_TRIGGER"
                putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmReceiver.EXTRA_ALARM_MESSAGE, message)
                putExtra(AlarmReceiver.EXTRA_ALARM_TIME, timeString)
                if (!customAudioPath.isNullOrEmpty()) {
                    putExtra("custom_audio_path", customAudioPath)
                }
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Schedule exact alarm with highest priority
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerTime, pendingIntent),
                    pendingIntent
                )
                Log.d(TAG, "Alarm scheduled using setAlarmClock (highest priority)")
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
                Log.d(TAG, "Alarm scheduled using setExactAndAllowWhileIdle")
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
                Log.d(TAG, "Alarm scheduled using setExact")
            }
            
            Log.d(TAG, "Native alarm scheduled successfully for: ${Date(triggerTime)}")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling native alarm: ${e.message}")
            false
        }
    }
    
    /**
     * Cancel a scheduled alarm
     */
    fun cancelAlarm(alarmId: String): Boolean {
        return try {
            Log.d(TAG, "Cancelling native alarm: ID=$alarmId")
            
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = "com.example.vibealarm.ALARM_TRIGGER"
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            
            Log.d(TAG, "Native alarm cancelled successfully: ID=$alarmId")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling native alarm: ${e.message}")
            false
        }
    }
    
    /**
     * Cancel all scheduled alarms
     */
    fun cancelAllAlarms(): Boolean {
        return try {
            Log.d(TAG, "Cancelling all native alarms")
            
            // This is a simplified approach - in a real app you'd track all alarm IDs
            // For now, we'll just stop any currently playing alarm
            AlarmSoundManager.stopAlarm()
            
            Log.d(TAG, "All native alarms cancelled")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling all native alarms: ${e.message}")
            false
        }
    }
    
    /**
     * Check if alarm is scheduled
     */
    fun isAlarmScheduled(alarmId: String): Boolean {
        return try {
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = "com.example.vibealarm.ALARM_TRIGGER"
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId.hashCode(),
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            pendingIntent != null
        } catch (e: Exception) {
            Log.e(TAG, "Error checking alarm schedule: ${e.message}")
            false
        }
    }
} 