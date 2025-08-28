import 'dart:io';
import 'package:flutter/services.dart';
import '../models/alarm.dart';

class NativeAlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.vibealarm/native_alarm');
  static const EventChannel _eventChannel = EventChannel('com.example.vibealarm/alarm_events');
  
  static final NativeAlarmService _instance = NativeAlarmService._internal();
  factory NativeAlarmService() => _instance;
  NativeAlarmService._internal();

  /// Schedule an alarm using native Android AlarmManager
  Future<bool> scheduleAlarm(Alarm alarm) async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return false;
      }

      // Convert alarm time string to DateTime
      final now = DateTime.now();
      final timeParts = alarm.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Create today's alarm time
      var alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // Adjust for AM/PM
      if (alarm.period == 'PM' && hour < 12) {
        alarmDateTime = alarmDateTime.add(const Duration(hours: 12));
      } else if (alarm.period == 'AM' && hour == 12) {
        alarmDateTime = alarmDateTime.subtract(const Duration(hours: 12));
      }
      
      // If alarm time has passed today, schedule for tomorrow
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }
      
      final triggerTime = alarmDateTime.millisecondsSinceEpoch;
      final result = await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': alarm.id,
        'triggerTime': triggerTime,
        'message': alarm.message ?? 'Time to wake up!',
        'timeString': alarm.time,
        'customAudioPath': alarm.audio.isNotEmpty ? alarm.audio : '',
      });

      print('Native alarm scheduled: $result for ${alarmDateTime.toString()}');
      return result ?? false;
    } catch (e) {
      print('Error scheduling native alarm: $e');
      return false;
    }
  }

  /// Cancel a scheduled alarm
  Future<bool> cancelAlarm(String alarmId) async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return false;
      }

      final result = await _channel.invokeMethod('cancelAlarm', {
        'alarmId': alarmId,
      });

      print('Native alarm cancelled: $result');
      return result ?? false;
    } catch (e) {
      print('Error cancelling native alarm: $e');
      return false;
    }
  }

  /// Cancel all scheduled alarms
  Future<bool> cancelAllAlarms() async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return false;
      }

      final result = await _channel.invokeMethod('cancelAllAlarms');
      print('All native alarms cancelled: $result');
      return result ?? false;
    } catch (e) {
      print('Error cancelling all native alarms: $e');
      return false;
    }
  }

  /// Check if an alarm is scheduled
  Future<bool> isAlarmScheduled(String alarmId) async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return false;
      }

      final result = await _channel.invokeMethod('isAlarmScheduled', {
        'alarmId': alarmId,
      });

      return result ?? false;
    } catch (e) {
      print('Error checking alarm schedule: $e');
      return false;
    }
  }

  /// Stop currently playing alarm
  Future<bool> stopAlarm() async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return false;
      }

      final result = await _channel.invokeMethod('stopAlarm');
      print('Alarm stopped: $result');
      return result ?? false;
    } catch (e) {
      print('Error stopping alarm: $e');
      return false;
    }
  }

  /// Get alarm events stream
  Stream<Map<String, dynamic>> get alarmEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }

  /// Initialize the native alarm service
  Future<void> initialize() async {
    try {
      if (!Platform.isAndroid) {
        print('Native alarm service only available on Android');
        return;
      }

      await _channel.invokeMethod('initialize');
      
      // Request exact alarm permission if needed
      await requestExactAlarmPermission();
      
      print('Native alarm service initialized');
    } catch (e) {
      print('Error initializing native alarm service: $e');
    }
  }
  
  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }

      final result = await _channel.invokeMethod('requestExactAlarmPermission');
      return result ?? false;
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
      return false;
    }
  }
} 