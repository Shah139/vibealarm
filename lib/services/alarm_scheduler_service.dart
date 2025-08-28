import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/native_alarm_service.dart';
import '../screens/alarm_ringing_screen.dart';

class AlarmSchedulerService {
  static final AlarmSchedulerService _instance = AlarmSchedulerService._internal();
  factory AlarmSchedulerService() => _instance;
  AlarmSchedulerService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _alarmTimers = {};
  final Map<String, AudioPlayer> _audioPlayers = {};
  final NativeAlarmService _nativeAlarmService = NativeAlarmService();
  bool _isInitialized = false;
  bool _useNativeAlarms = true; // Toggle between native and Flutter alarms
  
  // Callback for when alarms are triggered
  Function(Alarm)? onAlarmTriggered;

  /// Initialize the alarm scheduler service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Initializing AlarmSchedulerService...');

      // Initialize local notifications
      await _initializeLocalNotifications();
      print('Local notifications initialized');

      // Initialize audio session
      await _initializeAudioSession();
      print('Audio session initialized');

      // Initialize native alarm service if available
      if (_useNativeAlarms && Platform.isAndroid) {
        await _nativeAlarmService.initialize();
        print('Native alarm service initialized');
      }

      _isInitialized = true;
      print('AlarmSchedulerService initialized successfully');
    } catch (e) {
      print('Error initializing AlarmSchedulerService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'vibealarm_alarms',
        'VibeAlarm Alarms',
        description: 'Alarm notifications for VibeAlarm',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Initialize audio session for alarm playback
  Future<void> _initializeAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.alarm,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));
  }

  /// Schedule an alarm using native Android AlarmManager or Timer fallback
  Future<bool> scheduleAlarm(Alarm alarm) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('Scheduling alarm: ${alarm.id} for ${alarm.time}');

      // Calculate next alarm time
      final nextAlarmTime = _calculateNextAlarmTime(alarm);
      if (nextAlarmTime == null) {
        print('Could not calculate next alarm time for alarm: ${alarm.id}');
        return false;
      }

      // Calculate delay until alarm time
      final now = DateTime.now();
      final delay = nextAlarmTime.difference(now);
      
      print('Current time: $now');
      print('Alarm time: $nextAlarmTime');
      print('Delay: $delay');
      print('Delay in milliseconds: ${delay.inMilliseconds}');
      
      if (delay.isNegative) {
        print('Alarm time has already passed: ${alarm.id}');
        return false;
      }

      // Cancel existing timer if any
      _cancelAlarmTimer(alarm.id);

      bool scheduled = false;

      // Try to schedule using native Android AlarmManager first
      if (_useNativeAlarms && Platform.isAndroid) {
        try {
          print('Attempting to schedule native alarm for: ${alarm.id}');
          scheduled = await _nativeAlarmService.scheduleAlarm(alarm);
          if (scheduled) {
            print('Native alarm scheduled successfully for: ${alarm.id}');
            // Update alarm in database with next trigger time
            await _updateAlarmNextTriggerTime(alarm.id, nextAlarmTime);
            return true;
          } else {
            print('Native alarm scheduling failed, falling back to Timer for: ${alarm.id}');
          }
        } catch (e) {
          print('Error scheduling native alarm, falling back to Timer: $e');
        }
      }

      // Fallback to Timer-based scheduling
      if (!scheduled) {
        print('Creating Timer for alarm: ${alarm.id}');
        final timer = Timer(delay, () {
          print('Timer triggered for alarm: ${alarm.id}');
          _triggerAlarm(alarm);
        });

        _alarmTimers[alarm.id] = timer;
        print('Timer created and stored for alarm: ${alarm.id}');
        print('Total active timers: ${_alarmTimers.length}');
        
        // Update alarm in database with next trigger time
        await _updateAlarmNextTriggerTime(alarm.id, nextAlarmTime);
        scheduled = true;
      }
      
      return scheduled;
    } catch (e) {
      print('Error scheduling alarm: $e');
      return false;
    }
  }

  /// Schedule multiple alarms (for burst alarms)
  Future<bool> scheduleBurstAlarms(List<Alarm> alarms) async {
    try {
      print('Scheduling ${alarms.length} burst alarms');
      
      bool allScheduled = true;
      for (final alarm in alarms) {
        final success = await scheduleAlarm(alarm);
        if (!success) {
          allScheduled = false;
          print('Failed to schedule burst alarm: ${alarm.id}');
        }
      }
      
      return allScheduled;
    } catch (e) {
      print('Error scheduling burst alarms: $e');
      return false;
    }
  }

  /// Cancel a scheduled alarm
  Future<bool> cancelAlarm(String alarmId) async {
    try {
      print('Cancelling alarm: $alarmId');
      
      bool cancelled = false;
      
      // Try to cancel native alarm first
      if (_useNativeAlarms && Platform.isAndroid) {
        try {
          final nativeCancelled = await _nativeAlarmService.cancelAlarm(alarmId);
          if (nativeCancelled) {
            print('Native alarm cancelled successfully: $alarmId');
            cancelled = true;
          }
        } catch (e) {
          print('Error cancelling native alarm: $e');
        }
      }
      
      // Cancel Flutter timer as well
      _cancelAlarmTimer(alarmId);
      
      print('Alarm cancelled successfully: $alarmId');
      return true;
    } catch (e) {
      print('Error cancelling alarm: $e');
      return false;
    }
  }

  /// Cancel all scheduled alarms
  Future<bool> cancelAllAlarms() async {
    try {
      print('Cancelling all alarms');
      
      // Cancel all native alarms
      if (_useNativeAlarms && Platform.isAndroid) {
        try {
          await _nativeAlarmService.cancelAllAlarms();
          print('All native alarms cancelled');
        } catch (e) {
          print('Error cancelling native alarms: $e');
        }
      }
      
      // Cancel all Flutter timers
      for (final alarmId in _alarmTimers.keys) {
        _cancelAlarmTimer(alarmId);
      }
      
      print('All alarms cancelled successfully');
      return true;
    } catch (e) {
      print('Error cancelling all alarms: $e');
      return false;
    }
  }

  /// Cancel alarm timer
  void _cancelAlarmTimer(String alarmId) {
    final timer = _alarmTimers[alarmId];
    if (timer != null) {
      timer.cancel();
      _alarmTimers.remove(alarmId);
    }
  }

  /// Show full-screen alarm ringing UI
  void _showAlarmRingingUI(Alarm alarm) {
    try {
      print('=== SHOWING FULL SCREEN ALARM UI ===');
      print('Alarm ID: ${alarm.id}');
      print('Alarm Time: ${alarm.time}');
      print('Alarm Message: ${alarm.message}');
      print('Callback status: ${onAlarmTriggered != null ? "SET" : "NULL"}');
      
      // Call the callback to show full-screen UI
      if (onAlarmTriggered != null) {
        print('Calling onAlarmTriggered callback...');
        
        // Use a small delay to ensure the callback executes properly
        Timer(const Duration(milliseconds: 100), () {
          try {
            onAlarmTriggered!(alarm);
            print('Callback executed successfully');
          } catch (e) {
            print('Error in callback execution: $e');
          }
        });
        
      } else {
        print('ERROR: onAlarmTriggered callback is null!');
        print('This means the full-screen UI will not show!');
      }
      
    } catch (e) {
      print('Error showing full-screen alarm UI: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Trigger alarm
  void _triggerAlarm(Alarm alarm) async {
    try {
      print('=== ALARM TRIGGERED ===');
      print('Alarm ID: ${alarm.id}');
      print('Alarm Time: ${alarm.time}');
      print('Alarm Message: ${alarm.message}');
      print('Current time: ${DateTime.now()}');
      
      // Show notification
      await _showAlarmNotification(alarm.id, alarm.time, alarm.message ?? '');
      
      // Start audio playback if audio file exists
      if (alarm.audio.isNotEmpty) {
        await _startAlarmAudio(alarm.id, alarm.audio);
      } else {
        // Always start default audio
        await _startAlarmAudio(alarm.id, '');
      }
      
      // Always show full-screen UI
      _showAlarmRingingUI(alarm);
      
      // Handle recurring alarms
      if (alarm.frequency != 'Once') {
        await _scheduleNextRecurringAlarm(alarm);
      }
      
      // Remove timer from map
      _alarmTimers.remove(alarm.id);
      print('Timer removed for alarm: ${alarm.id}');
      print('Remaining active timers: ${_alarmTimers.length}');
      
    } catch (e) {
      print('Error triggering alarm: $e');
    }
  }

  /// Trigger alarm immediately (for testing)
  Future<void> triggerAlarmImmediately(Alarm alarm) async {
    try {
      print('=== TRIGGERING FULL SCREEN ALARM ===');
      print('Alarm ID: ${alarm.id}');
      print('Alarm Time: ${alarm.time}');
      print('Alarm Message: ${alarm.message}');
      print('Current time: ${DateTime.now()}');
      
      // Show notification
      await _showAlarmNotification(alarm.id, alarm.time, alarm.message ?? '');
      
      // Start audio playback
      if (alarm.audio.isNotEmpty) {
        await _startAlarmAudio(alarm.id, alarm.audio);
      } else {
        // Always start default audio
        await _startAlarmAudio(alarm.id, '');
      }
      
      // Show full-screen UI
      _showAlarmRingingUI(alarm);
      
      print('Full screen alarm triggered successfully');
      
    } catch (e) {
      print('Error triggering full screen alarm: $e');
    }
  }

  /// Start alarm audio playback
  Future<void> _startAlarmAudio(String alarmId, String audioPath) async {
    try {
      print('Starting audio playback for alarm: $alarmId');
      
      // Use default audio if no custom audio specified
      final finalAudioPath = audioPath.isNotEmpty 
          ? audioPath 
          : 'assets/tunes/fire_alarm.mp3';
      
      print('Audio path: $finalAudioPath');
      
      // Create new audio player for this alarm
      final audioPlayer = AudioPlayer();
      _audioPlayers[alarmId] = audioPlayer;
      
      // Set audio session for alarm playback
      if (finalAudioPath.startsWith('assets/')) {
        // For asset files, use asset source
        await audioPlayer.setAudioSource(
          AudioSource.asset(finalAudioPath),
          preload: true,
        );
      } else {
        // For file paths, use file source
        await audioPlayer.setAudioSource(
          AudioSource.uri(Uri.file(finalAudioPath)),
          preload: true,
        );
      }
      
      // Set volume and looping
      await audioPlayer.setVolume(1.0);
      await audioPlayer.setLoopMode(LoopMode.one);
      
      // Start playback
      await audioPlayer.play();
      
      print('Audio playback started for alarm: $alarmId');
      
      // Keep audio playing for at least 30 seconds
      Timer(const Duration(seconds: 30), () {
        _stopAlarmAudio(alarmId);
      });
      
    } catch (e) {
      print('Error starting alarm audio: $e');
      // Fallback to default system sound
      print('Falling back to default system sound');
    }
  }

  /// Stop alarm audio playback
  Future<void> _stopAlarmAudio(String alarmId) async {
    try {
      final audioPlayer = _audioPlayers[alarmId];
      if (audioPlayer != null) {
        await audioPlayer.stop();
        await audioPlayer.dispose();
        _audioPlayers.remove(alarmId);
        print('Audio playback stopped for alarm: $alarmId');
      }
      
      // Stop native alarm if it's playing
      if (_useNativeAlarms && Platform.isAndroid) {
        try {
          await _nativeAlarmService.stopAlarm();
          print('Native alarm stopped for: $alarmId');
        } catch (e) {
          print('Error stopping native alarm: $e');
        }
      }
    } catch (e) {
      print('Error stopping alarm audio: $e');
    }
  }

  /// Stop all alarm audio
  Future<void> _stopAllAlarmAudio() async {
    try {
      for (final audioPlayer in _audioPlayers.values) {
        await audioPlayer.stop();
        await audioPlayer.dispose();
      }
      _audioPlayers.clear();
      print('All alarm audio stopped');
    } catch (e) {
      print('Error stopping all alarm audio: $e');
    }
  }

  /// Public method to stop alarm audio (for testing)
  Future<void> stopAlarmAudio(String alarmId) async {
    await _stopAlarmAudio(alarmId);
  }

  /// Public method to stop all alarm audio (for testing)
  Future<void> stopAllAlarmAudio() async {
    await _stopAllAlarmAudio();
  }

  /// Trigger full-screen alarm UI (for testing)
  Future<void> triggerFullScreenAlarm(Alarm alarm) async {
    try {
      print('=== TRIGGERING FULL SCREEN ALARM ===');
      print('Alarm ID: ${alarm.id}');
      print('Alarm Time: ${alarm.time}');
      print('Alarm Message: ${alarm.message}');
      print('Current time: ${DateTime.now()}');
      
      // Call the callback to show the UI
      onAlarmTriggered?.call(alarm);
      
      print('Full screen alarm triggered successfully');
      
    } catch (e) {
      print('Error triggering full screen alarm: $e');
    }
  }

  /// Stop all active alarms (timers and audio)
  Future<void> stopAllActiveAlarms() async {
    try {
      print('Stopping all active alarms...');
      
      // Cancel all timers
      for (final timer in _alarmTimers.values) {
        timer.cancel();
      }
      _alarmTimers.clear();
      
      // Stop all audio
      await _stopAllAlarmAudio();
      
      print('All active alarms stopped');
    } catch (e) {
      print('Error stopping all active alarms: $e');
    }
  }

  /// Get next alarm time based on frequency
  DateTime? _calculateNextAlarmTime(Alarm alarm) {
    try {
      final now = DateTime.now();
      final timeParts = alarm.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      print('Calculating alarm time: ${alarm.time} ${alarm.period}');
      print('Current time: $now');
      print('Parsed hour: $hour, minute: $minute');
      
      // Create today's alarm time with proper 12-hour format handling
      var nextAlarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      print('Initial alarm time: $nextAlarmTime');
      
      // Adjust for AM/PM - only modify if the period doesn't match the 24-hour format
      if (alarm.period == 'PM') {
        if (hour < 12) {
          // 1 PM to 11 PM: add 12 hours
          nextAlarmTime = nextAlarmTime.add(const Duration(hours: 12));
          print('Adjusted for PM (hour < 12): $nextAlarmTime');
        } else if (hour == 12) {
          // 12 PM: keep as is (noon)
          print('12 PM - keeping as is: $nextAlarmTime');
        }
        // 12 PM to 11 PM: no adjustment needed
      } else if (alarm.period == 'AM') {
        if (hour == 12) {
          // 12 AM: subtract 12 hours (midnight)
          nextAlarmTime = nextAlarmTime.subtract(const Duration(hours: 12));
          print('Adjusted for 12 AM: $nextAlarmTime');
        }
        // 1 AM to 11 AM: no adjustment needed
      }
      
      print('After AM/PM adjustment: $nextAlarmTime');
      
      // If alarm time has passed today, calculate next occurrence
      if (nextAlarmTime.isBefore(now)) {
        print('Alarm time has passed, calculating next occurrence');
        nextAlarmTime = _calculateNextOccurrence(nextAlarmTime, alarm.frequency);
      }
      
      print('Final calculated alarm time: $nextAlarmTime');
      return nextAlarmTime;
    } catch (e) {
      print('Error calculating next alarm time: $e');
      return null;
    }
  }

  /// Calculate next occurrence based on frequency
  DateTime _calculateNextOccurrence(DateTime baseTime, String frequency) {
    switch (frequency) {
      case 'Once':
        // If it's a one-time alarm and time has passed, return null
        return baseTime;
        
      case 'Everyday':
        return baseTime.add(const Duration(days: 1));
        
      case 'Weekdays':
        var nextTime = baseTime;
        do {
          nextTime = nextTime.add(const Duration(days: 1));
        } while (nextTime.weekday > 5); // Saturday = 6, Sunday = 7
        return nextTime;
        
      case 'Weekends':
        var nextTime = baseTime;
        do {
          nextTime = nextTime.add(const Duration(days: 1));
        } while (nextTime.weekday <= 5); // Monday = 1, Friday = 5
        return nextTime;
        
      case 'Monday':
      case 'Tuesday':
      case 'Wednesday':
      case 'Thursday':
      case 'Friday':
      case 'Saturday':
      case 'Sunday':
        final targetWeekday = _getWeekdayNumber(frequency);
        var nextTime = baseTime;
        do {
          nextTime = nextTime.add(const Duration(days: 1));
        } while (nextTime.weekday != targetWeekday);
        return nextTime;
        
      default:
        return baseTime.add(const Duration(days: 1));
    }
  }

  /// Get weekday number from string
  int _getWeekdayNumber(String weekday) {
    switch (weekday) {
      case 'Monday': return 1;
      case 'Tuesday': return 2;
      case 'Wednesday': return 3;
      case 'Thursday': return 4;
      case 'Friday': return 5;
      case 'Saturday': return 6;
      case 'Sunday': return 7;
      default: return 1;
    }
  }

  /// Update alarm next trigger time in database
  Future<void> _updateAlarmNextTriggerTime(String alarmId, DateTime nextTriggerTime) async {
    try {
      // This would require adding a nextTriggerTime field to the Alarm model
      // For now, we'll just log it
      print('Next trigger time for alarm $alarmId: $nextTriggerTime');
    } catch (e) {
      print('Error updating alarm next trigger time: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could launch specific alarm screen
  }

  /// Show alarm notification
  Future<void> _showAlarmNotification(String alarmId, String alarmTime, String message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'vibealarm_alarms',
        'VibeAlarm Alarms',
        channelDescription: 'Alarm notifications for VibeAlarm',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        // Add vibration pattern for 30 seconds
        vibrationPattern: Int64List.fromList([
          0, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500, 200, 500
        ]),
        // Set sound to default alarm sound
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _localNotifications.show(
        alarmId.hashCode,
        'Alarm - $alarmTime',
        message.isNotEmpty ? message : 'Time to wake up!',
        notificationDetails,
      );
      
      print('Alarm notification shown for: $alarmId');
    } catch (e) {
      print('Error showing alarm notification: $e');
    }
  }

  /// Schedule next recurring alarm
  Future<void> _scheduleNextRecurringAlarm(Alarm alarm) async {
    try {
      print('Scheduling next recurring alarm for: ${alarm.id} with frequency: ${alarm.frequency}');
      
      // Schedule the next occurrence
      await scheduleAlarm(alarm);
    } catch (e) {
      print('Error scheduling next recurring alarm: $e');
    }
  }

  /// Get all scheduled alarms
  Future<List<Alarm>> getScheduledAlarms() async {
    try {
      // Get active alarms from database
      final activeAlarms = await AlarmService.getAllAlarms();
      
      // Filter out alarms that have already passed
      final now = DateTime.now();
      final validAlarms = <Alarm>[];
      
      for (final alarm in activeAlarms) {
        final nextTime = _calculateNextAlarmTime(alarm);
        if (nextTime != null && nextTime.isAfter(now)) {
          validAlarms.add(alarm);
        }
      }
      
      return validAlarms;
    } catch (e) {
      print('Error getting scheduled alarms: $e');
      return [];
    }
  }

  /// Check if alarm is scheduled
  Future<bool> isAlarmScheduled(String alarmId) async {
    try {
      return _alarmTimers.containsKey(alarmId);
    } catch (e) {
      print('Error checking if alarm is scheduled: $e');
      return false;
    }
  }

  /// Debug method to show all active timers
  void debugActiveTimers() {
    print('=== ACTIVE TIMERS DEBUG ===');
    print('Total active timers: ${_alarmTimers.length}');
    if (_alarmTimers.isEmpty) {
      print('No active timers');
    } else {
      _alarmTimers.forEach((alarmId, timer) {
        print('Timer for alarm: $alarmId');
      });
    }
    print('==========================');
  }

  /// Restore alarms after device reboot
  Future<void> restoreAlarmsAfterBoot() async {
    try {
      print('Restoring alarms after device reboot...');
      
      final activeAlarms = await AlarmService.getAllAlarms();
      print('Found ${activeAlarms.length} active alarms to restore');
      
      for (final alarm in activeAlarms) {
        if (alarm.isActive) {
          await scheduleAlarm(alarm);
        }
      }
      
      print('Alarms restored successfully');
    } catch (e) {
      print('Error restoring alarms after boot: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      // Cancel all timers
      for (final timer in _alarmTimers.values) {
        timer.cancel();
      }
      _alarmTimers.clear();
      
      // Stop all audio players
      await _stopAllAlarmAudio();
      
      await WakelockPlus.disable();
      print('AlarmSchedulerService disposed');
    } catch (e) {
      print('Error disposing AlarmSchedulerService: $e');
    }
  }
} 