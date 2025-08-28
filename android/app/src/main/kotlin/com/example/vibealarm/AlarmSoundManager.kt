package com.example.vibealarm

import android.media.MediaPlayer
import android.os.Vibrator
import android.util.Log

object AlarmSoundManager {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    
    fun setMediaPlayer(player: MediaPlayer) {
        mediaPlayer = player
    }
    
    fun setVibrator(vib: Vibrator) {
        vibrator = vib
    }
    
    fun stopAlarm() {
        try {
            // Stop media player
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
                mediaPlayer = null
                Log.d("AlarmSoundManager", "Media player stopped and released")
            }
            
            // Stop vibration
            vibrator?.let { vib ->
                vib.cancel()
                vibrator = null
                Log.d("AlarmSoundManager", "Vibration stopped")
            }
            
        } catch (e: Exception) {
            Log.e("AlarmSoundManager", "Error stopping alarm: ${e.message}")
        }
    }
    
    fun isAlarmPlaying(): Boolean {
        return mediaPlayer?.isPlaying == true || vibrator != null
    }
} 