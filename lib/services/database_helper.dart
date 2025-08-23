import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vibealarm.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main alarms table
    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        time TEXT NOT NULL,
        period TEXT NOT NULL,
        frequency TEXT NOT NULL,
        audio TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        message TEXT,
        mood TEXT,
        createdAt TEXT NOT NULL,
        isBurstAlarm INTEGER NOT NULL,
        burstAlarmGroupId TEXT,
        nextAlarmTime TEXT,
        lastTriggered TEXT
      )
    ''');

    // Burst alarm groups table for managing burst alarm relationships
    await db.execute('''
      CREATE TABLE burst_alarm_groups (
        id TEXT PRIMARY KEY,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        totalAlarms INTEGER NOT NULL,
        audio TEXT NOT NULL,
        frequency TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');

    // Alarm history table for tracking when alarms were triggered
    await db.execute('''
      CREATE TABLE alarm_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alarmId TEXT NOT NULL,
        triggeredAt TEXT NOT NULL,
        wasSnoozed INTEGER NOT NULL,
        snoozeCount INTEGER NOT NULL,
        FOREIGN KEY (alarmId) REFERENCES alarms (id) ON DELETE CASCADE
      )
    ''');

    // Audio table for AI-generated and custom audio files (enhanced)
    await db.execute('''
      CREATE TABLE audio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        text TEXT,
        mood TEXT NOT NULL,
        localPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        voiceName TEXT,
        pitch REAL,
        speed REAL,
        languageCode TEXT,
        duration INTEGER,
        fileSize TEXT,
        isGenerated INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Audio library table for managing pre-installed audio files
    await db.execute('''
      CREATE TABLE audio_library (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        category TEXT NOT NULL,
        duration INTEGER,
        isCustom INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_alarms_time ON alarms(time)');
    await db.execute('CREATE INDEX idx_alarms_active ON alarms(isActive)');
    await db.execute('CREATE INDEX idx_alarms_frequency ON alarms(frequency)');
    await db.execute('CREATE INDEX idx_burst_groups_active ON burst_alarm_groups(isActive)');
    await db.execute('CREATE INDEX idx_audio_mood ON audio(mood)');
    await db.execute('CREATE INDEX idx_audio_language ON audio(languageCode)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Add new columns to audio table for enhanced TTS support
      try {
        await db.execute('ALTER TABLE audio ADD COLUMN voiceName TEXT');
        await db.execute('ALTER TABLE audio ADD COLUMN pitch REAL');
        await db.execute('ALTER TABLE audio ADD COLUMN speed REAL');
        await db.execute('ALTER TABLE audio ADD COLUMN languageCode TEXT');
        await db.execute('ALTER TABLE audio ADD COLUMN duration INTEGER');
        await db.execute('ALTER TABLE audio ADD COLUMN fileSize TEXT');
        await db.execute('ALTER TABLE audio ADD COLUMN isGenerated INTEGER NOT NULL DEFAULT 1');
        
        // Create new indexes
        await db.execute('CREATE INDEX idx_audio_mood ON audio(mood)');
        await db.execute('CREATE INDEX idx_audio_language ON audio(languageCode)');
      } catch (e) {
        print('Database upgrade error: $e');
      }
    }
  }

  // CRUD Operations for Alarms
  Future<int> insertAlarm(Alarm alarm) async {
    final db = await database;
    return await db.insert('alarms', _alarmToMap(alarm));
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final db = await database;
    return await db.update(
      'alarms',
      _alarmToMap(alarm),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(String id) async {
    final db = await database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alarms',
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => _mapToAlarm(maps[i]));
  }

  Future<List<Alarm>> getActiveAlarms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alarms',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'time ASC',
    );
    return List.generate(maps.length, (i) => _mapToAlarm(maps[i]));
  }

  Future<Alarm?> getAlarmById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _mapToAlarm(maps.first);
    }
    return null;
  }

  Future<List<Alarm>> getAlarmsByFrequency(String frequency) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alarms',
      where: 'frequency = ?',
      whereArgs: [frequency],
      orderBy: 'time ASC',
    );
    return List.generate(maps.length, (i) => _mapToAlarm(maps[i]));
  }

  Future<List<Alarm>> getBurstAlarms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alarms',
      where: 'isBurstAlarm = ?',
      whereArgs: [1],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => _mapToAlarm(maps[i]));
  }

  // Burst Alarm Group Operations
  Future<int> insertBurstAlarmGroup(Map<String, dynamic> group) async {
    final db = await database;
    return await db.insert('burst_alarm_groups', group);
  }

  Future<List<Map<String, dynamic>>> getBurstAlarmGroups() async {
    final db = await database;
    return await db.query('burst_alarm_groups', orderBy: 'createdAt DESC');
  }

  // Alarm History Operations
  Future<int> insertAlarmHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('alarm_history', history);
  }

  Future<List<Map<String, dynamic>>> getAlarmHistory(String alarmId) async {
    final db = await database;
    return await db.query(
      'alarm_history',
      where: 'alarmId = ?',
      whereArgs: [alarmId],
      orderBy: 'triggeredAt DESC',
    );
  }

  // Audio Operations (AI-generated and custom audio)
  Future<int> insertAudio(Map<String, dynamic> audio) async {
    final db = await database;
    return await db.insert('audio', audio);
  }

  Future<List<Map<String, dynamic>>> getAllAudio() async {
    final db = await database;
    return await db.query('audio', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getAudioById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audio',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAudioByMood(String mood) async {
    final db = await database;
    return await db.query(
      'audio',
      where: 'mood = ?',
      whereArgs: [mood],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateAudio(Map<String, dynamic> audio) async {
    final db = await database;
    return await db.update(
      'audio',
      audio,
      where: 'id = ?',
      whereArgs: [audio['id']],
    );
  }

  Future<int> deleteAudio(int id) async {
    final db = await database;
    return await db.delete(
      'audio',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Audio Library Operations (pre-installed audio)
  Future<int> insertAudioLibrary(Map<String, dynamic> audio) async {
    final db = await database;
    return await db.insert('audio_library', audio);
  }

  Future<List<Map<String, dynamic>>> getAudioLibrary() async {
    final db = await database;
    return await db.query('audio_library', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getAudioByCategory(String category) async {
    final db = await database;
    return await db.query(
      'audio_library',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
  }

  // Utility Methods
  Future<void> toggleAlarm(String id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE alarms 
      SET isActive = CASE WHEN isActive = 1 THEN 0 ELSE 1 END 
      WHERE id = ?
    ''', [id]);
  }

  Future<void> deleteAllAlarms() async {
    final db = await database;
    await db.delete('alarms');
  }

  Future<int> getAlarmCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM alarms');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveAlarmCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM alarms WHERE isActive = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAudioCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM audio');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAudioByMoodCount(String mood) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM audio WHERE mood = ?', [mood]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Data Conversion Methods
  Map<String, dynamic> _alarmToMap(Alarm alarm) {
    return {
      'id': alarm.id,
      'time': alarm.time,
      'period': alarm.period,
      'frequency': alarm.frequency,
      'audio': alarm.audio,
      'isActive': alarm.isActive ? 1 : 0,
      'message': alarm.message,
      'mood': alarm.mood,
      'createdAt': alarm.createdAt.toIso8601String(),
      'isBurstAlarm': alarm.isBurstAlarm ? 1 : 0,
      'burstAlarmGroupId': null, // Can be used for future burst alarm grouping
      'nextAlarmTime': null, // Can be used for scheduling
      'lastTriggered': null, // Can be used for tracking
    };
  }

  Alarm _mapToAlarm(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      time: map['time'],
      period: map['period'],
      frequency: map['frequency'],
      audio: map['audio'],
      isActive: map['isActive'] == 1,
      message: map['message'],
      mood: map['mood'],
      createdAt: DateTime.parse(map['createdAt']),
      isBurstAlarm: map['isBurstAlarm'] == 1,
      burstAlarmTimes: null, // Can be populated from burst_alarm_groups table
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 