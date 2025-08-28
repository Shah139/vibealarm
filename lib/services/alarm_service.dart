import '../models/alarm.dart';
import 'database_helper.dart';
import 'alarm_scheduler_service.dart';

class AlarmService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  static final AlarmSchedulerService _schedulerService = AlarmSchedulerService();
  
  // Get all alarms
  static Future<List<Alarm>> getAllAlarms() async {
    return await _dbHelper.getAllAlarms();
  }

  // Get active alarms only
  static Future<List<Alarm>> getActiveAlarms() async {
    return await _dbHelper.getActiveAlarms();
  }

  // Add new alarm and schedule it
  static Future<void> addAlarm(Alarm alarm) async {
    await _dbHelper.insertAlarm(alarm);
    
    // Schedule the alarm if it's active
    if (alarm.isActive) {
      await _schedulerService.scheduleAlarm(alarm);
    }
  }

  // Update existing alarm and reschedule if needed
  static Future<void> updateAlarm(Alarm updatedAlarm) async {
    // Cancel existing alarm if it was scheduled
    final existingAlarm = await getAlarmById(updatedAlarm.id);
    if (existingAlarm?.isScheduled == true) {
      await _schedulerService.cancelAlarm(updatedAlarm.id);
    }
    
    await _dbHelper.updateAlarm(updatedAlarm);
    
    // Schedule the updated alarm if it's active
    if (updatedAlarm.isActive) {
      await _schedulerService.scheduleAlarm(updatedAlarm);
    }
  }

  // Delete alarm and cancel its schedule
  static Future<void> deleteAlarm(String alarmId) async {
    // Cancel the scheduled alarm
    await _schedulerService.cancelAlarm(alarmId);
    
    // Delete from database
    await _dbHelper.deleteAlarm(alarmId);
  }

  // Toggle alarm active state and schedule/cancel accordingly
  static Future<void> toggleAlarm(String alarmId) async {
    final alarm = await getAlarmById(alarmId);
    if (alarm == null) return;
    
    final newActiveState = !alarm.isActive;
    
    if (newActiveState) {
      // Activate and schedule alarm
      final updatedAlarm = alarm.copyWith(isActive: true);
      await _dbHelper.updateAlarm(updatedAlarm);
      await _schedulerService.scheduleAlarm(updatedAlarm);
    } else {
      // Deactivate and cancel alarm
      final updatedAlarm = alarm.copyWith(isActive: false);
      await _dbHelper.updateAlarm(updatedAlarm);
      await _schedulerService.cancelAlarm(alarmId);
    }
  }

  /// Populate audio names for existing alarms (fixes "Unknown Audio" issue)
  static Future<void> populateAudioNamesForExistingAlarms() async {
    await _dbHelper.populateAudioNamesForExistingAlarms();
  }

  /// Schedule an alarm using Android AlarmManager
  static Future<bool> scheduleAlarm(Alarm alarm) async {
    try {
      return await _schedulerService.scheduleAlarm(alarm);
    } catch (e) {
      print('Error scheduling alarm: $e');
      return false;
    }
  }

  /// Cancel a scheduled alarm
  static Future<bool> cancelScheduledAlarm(String alarmId) async {
    try {
      return await _schedulerService.cancelAlarm(alarmId);
    } catch (e) {
      print('Error canceling scheduled alarm: $e');
      return false;
    }
  }

  /// Cancel all scheduled alarms
  static Future<bool> cancelAllScheduledAlarms() async {
    try {
      return await _schedulerService.cancelAllAlarms();
    } catch (e) {
      print('Error canceling all scheduled alarms: $e');
      return false;
    }
  }

  /// Get all scheduled alarms
  static Future<List<Alarm>> getScheduledAlarms() async {
    try {
      return await _schedulerService.getScheduledAlarms();
    } catch (e) {
      print('Error getting scheduled alarms: $e');
      return [];
    }
  }

  /// Check if an alarm is scheduled
  static Future<bool> isAlarmScheduled(String alarmId) async {
    try {
      return await _schedulerService.isAlarmScheduled(alarmId);
    } catch (e) {
      print('Error checking if alarm is scheduled: $e');
      return false;
    }
  }

  /// Restore alarms after device reboot
  static Future<void> restoreAlarmsAfterBoot() async {
    try {
      await _schedulerService.restoreAlarmsAfterBoot();
    } catch (e) {
      print('Error restoring alarms after boot: $e');
    }
  }

  /// Manually trigger an alarm (for testing purposes)
  static Future<bool> triggerAlarm(String alarmId) async {
    try {
      // Get the alarm from database
      final alarm = await getAlarmById(alarmId);
      if (alarm == null) {
        print('Alarm not found: $alarmId');
        return false;
      }

      // Create a test alarm if the original doesn't exist
      final testAlarm = alarm.copyWith(
        id: alarmId,
        message: 'Manual test trigger',
      );

      // Trigger the alarm immediately
      await _schedulerService.triggerAlarmImmediately(testAlarm);
      return true;
    } catch (e) {
      print('Error triggering alarm: $e');
      return false;
    }
  }

  /// Get the scheduler service instance
  static AlarmSchedulerService? getSchedulerService() {
    return _schedulerService;
  }

  /// Initialize the alarm scheduler service
  static Future<void> initializeScheduler() async {
    try {
      print('Initializing AlarmSchedulerService...');
      await _schedulerService.initialize();
      
      // Set up the alarm triggered callback
      _schedulerService.onAlarmTriggered = (alarm) {
        print('Alarm triggered callback called for: ${alarm.id}');
        // This will be handled by the main app through the global navigator
      };
      
      print('AlarmSchedulerService initialized successfully');
    } catch (e) {
      print('Error initializing AlarmSchedulerService: $e');
    }
  }

  // Generate unique ID for new alarms
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Get default frequency options
  static List<String> getFrequencyOptions() {
    return [
      'Once',
      'Everyday',
      'Weekdays',
      'Weekends',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
  }

  // Additional database methods
  static Future<Alarm?> getAlarmById(String id) async {
    return await _dbHelper.getAlarmById(id);
  }

  static Future<List<Alarm>> getAlarmsByFrequency(String frequency) async {
    return await _dbHelper.getAlarmsByFrequency(frequency);
  }

  static Future<List<Alarm>> getBurstAlarms() async {
    return await _dbHelper.getBurstAlarms();
  }

  static Future<int> getAlarmCount() async {
    return await _dbHelper.getAlarmCount();
  }

  static Future<int> getActiveAlarmCount() async {
    return await _dbHelper.getActiveAlarmCount();
  }

  static Future<void> deleteAllAlarms() async {
    // Cancel all scheduled alarms first
    await cancelAllScheduledAlarms();
    
    // Delete from database
    await _dbHelper.deleteAllAlarms();
  }
} 