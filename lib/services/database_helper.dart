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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating new database with version: $version');
    
    // Main alarms table
    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        time TEXT NOT NULL,
        period TEXT NOT NULL,
        frequency TEXT NOT NULL,
        audio TEXT NOT NULL,
        audioName TEXT NOT NULL,
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
    print('Created alarms table with audioName column');

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
    print('Created burst_alarm_groups table');

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
    print('Created alarm_history table');

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
    print('Created audio table');

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
    print('Created audio_library table');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_alarms_time ON alarms(time)');
    await db.execute('CREATE INDEX idx_alarms_active ON alarms(isActive)');
    await db.execute('CREATE INDEX idx_alarms_frequency ON alarms(frequency)');
    await db.execute('CREATE INDEX idx_burst_groups_active ON burst_alarm_groups(isActive)');
    await db.execute('CREATE INDEX idx_audio_mood ON audio(mood)');
    await db.execute('CREATE INDEX idx_audio_language ON audio(languageCode)');
    print('Created all indexes');
    
    print('Database creation completed successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgrade: $oldVersion -> $newVersion');
    
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      print('Upgrading to version 2: Adding audio table columns...');
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
        print('Version 2 upgrade completed successfully');
      } catch (e) {
        print('Database upgrade error: $e');
      }
    }
    
    if (oldVersion < 3) {
      print('Upgrading to version 3: Adding audioName column...');
      // Add audioName column to alarms table
      try {
        await db.execute('ALTER TABLE alarms ADD COLUMN audioName TEXT');
        print('Version 3 upgrade completed successfully');
      } catch (e) {
        print('Database upgrade error adding audioName: $e');
      }
    }
    
    if (oldVersion < 4) {
      print('Upgrading to version 4: Populating audioName for existing alarms...');
      // Populate audioName for existing alarms (this will run for both new and existing databases)
      try {
        await _populateAudioNamesForExistingAlarms(db);
        print('Version 4 upgrade completed successfully');
      } catch (e) {
        print('Database upgrade error populating audioName: $e');
      }
    }
  }

  /// Populate audioName field for existing alarms by mapping audio paths to names
  Future<void> _populateAudioNamesForExistingAlarms(Database db) async {
    try {
      print('Starting audioName population for existing alarms...');
      
      // Get all existing alarms that don't have audioName set
      final alarmsWithoutName = await db.query(
        'alarms',
        where: 'audioName IS NULL OR audioName = ?',
        whereArgs: ['Unknown Audio'],
      );

      print('Found ${alarmsWithoutName.length} alarms without audioName');

      if (alarmsWithoutName.isEmpty) {
        print('No alarms need audioName population');
        return;
      }

      // Also check all alarms to see their current state
      final allAlarms = await db.query('alarms');
      print('Total alarms in database: ${allAlarms.length}');
      for (final alarm in allAlarms) {
        print('Alarm ${alarm['id']}: audio="${alarm['audio']}", audioName="${alarm['audioName']}"');
      }

      for (final alarm in alarmsWithoutName) {
        final audioPath = alarm['audio'] as String;
        String? audioName;
        
        print('Processing alarm ${alarm['id']} with audio path: $audioPath');

        // Try to find the audio name from the audio table (AI-generated)
        final audioResult = await db.query(
          'audio',
          where: 'localPath = ?',
          whereArgs: [audioPath],
        );

        print('Found ${audioResult.length} audio records for path: $audioPath');
        if (audioResult.isNotEmpty) {
          audioName = audioResult.first['name'] as String?;
          print('Audio name from audio table: $audioName');
        }

        // If not found in audio table, try audio_library table (pre-installed)
        if (audioName == null) {
          final libraryResult = await db.query(
            'audio_library',
            where: 'filePath = ?',
            whereArgs: [audioPath],
          );

          print('Found ${libraryResult.length} library records for path: $audioPath');
          if (libraryResult.isNotEmpty) {
            audioName = libraryResult.first['name'] as String?;
            print('Audio name from library table: $audioName');
          }
        }

        // If still not found, try to extract name from path or use a default
        if (audioName == null) {
          // Try to extract name from path
          final pathParts = audioPath.split('/');
          final fileName = pathParts.last;
          if (fileName.isNotEmpty && fileName != audioPath) {
            audioName = fileName.replaceAll('.mp3', '').replaceAll('.wav', '');
            print('Extracted audio name from path: $audioName');
          } else {
            // Use mood or default name
            final mood = alarm['mood'] as String?;
            audioName = mood != null ? '$mood Audio' : 'Custom Audio';
            print('Using fallback audio name: $audioName');
          }
        }

        // Update the alarm with the found audio name
        if (audioName != null) {
          await db.update(
            'alarms',
            {'audioName': audioName},
            where: 'id = ?',
            whereArgs: [alarm['id']],
          );
          print('Updated alarm ${alarm['id']} with audioName: $audioName');
        }
      }

      print('Finished populating audioName for existing alarms');
    } catch (e) {
      print('Error populating audioName for existing alarms: $e');
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
      'audioName': alarm.audioName, // Added audioName field
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
      audioName: map['audioName'] ?? 'Unknown Audio', // Added audioName field with fallback
      isActive: map['isActive'] == 1,
      message: map['message'],
      mood: map['mood'],
      createdAt: DateTime.parse(map['createdAt']),
      isBurstAlarm: map['isBurstAlarm'] == 1,
      burstAlarmTimes: null, // Can be populated from burst_alarms table
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Manually populate audioName for existing alarms (useful for debugging or manual fixes)
  Future<void> populateAudioNamesForExistingAlarms() async {
    final db = await database;
    await _populateAudioNamesForExistingAlarms(db);
  }
} 