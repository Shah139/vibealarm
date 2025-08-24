import '../models/alarm.dart';
import 'database_helper.dart';

class AlarmService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Get all alarms
  static Future<List<Alarm>> getAllAlarms() async {
    return await _dbHelper.getAllAlarms();
  }

  // Get active alarms only
  static Future<List<Alarm>> getActiveAlarms() async {
    return await _dbHelper.getActiveAlarms();
  }

  // Add new alarm
  static Future<void> addAlarm(Alarm alarm) async {
    await _dbHelper.insertAlarm(alarm);
  }

  // Update existing alarm
  static Future<void> updateAlarm(Alarm updatedAlarm) async {
    await _dbHelper.updateAlarm(updatedAlarm);
  }

  // Delete alarm
  static Future<void> deleteAlarm(String alarmId) async {
    await _dbHelper.deleteAlarm(alarmId);
  }

  // Toggle alarm active state
  static Future<void> toggleAlarm(String alarmId) async {
    await _dbHelper.toggleAlarm(alarmId);
  }

  /// Populate audio names for existing alarms (fixes "Unknown Audio" issue)
  static Future<void> populateAudioNamesForExistingAlarms() async {
    await _dbHelper.populateAudioNamesForExistingAlarms();
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
    await _dbHelper.deleteAllAlarms();
  }
} 