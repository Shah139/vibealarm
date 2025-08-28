package com.example.vibealarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device boot completed, restoring alarms...")
            
            // Launch the Flutter app to restore alarms
            try {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent?.putExtra("restore_alarms", true)
                context.startActivity(launchIntent)
                Log.d("BootReceiver", "Flutter app launched to restore alarms")
            } catch (e: Exception) {
                Log.e("BootReceiver", "Error launching Flutter app: ${e.message}")
            }
        }
    }
} 