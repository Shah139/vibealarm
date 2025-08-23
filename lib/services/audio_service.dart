import 'database_helper.dart';

class AudioService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insert new AI-generated or custom audio
  static Future<int> insertAudio({
    String? name,
    String? text,
    required String mood,
    required String localPath,
  }) async {
    final audio = {
      'name': name,
      'text': text,
      'mood': mood,
      'localPath': localPath,
      'createdAt': DateTime.now().toIso8601String(),
    };

    return await _dbHelper.insertAudio(audio);
  }

  // Get all audio files
  static Future<List<Map<String, dynamic>>> getAllAudio() async {
    return await _dbHelper.getAllAudio();
  }

  // Get audio by ID
  static Future<Map<String, dynamic>?> getAudioById(int id) async {
    return await _dbHelper.getAudioById(id);
  }

  // Get audio by mood
  static Future<List<Map<String, dynamic>>> getAudioByMood(String mood) async {
    return await _dbHelper.getAudioByMood(mood);
  }

  // Update audio file
  static Future<int> updateAudio({
    required int id,
    String? name,
    String? text,
    String? mood,
    String? localPath,
  }) async {
    final audio = {
      'id': id,
      if (name != null) 'name': name,
      if (text != null) 'text': text,
      if (mood != null) 'mood': mood,
      if (localPath != null) 'localPath': localPath,
    };

    return await _dbHelper.updateAudio(audio);
  }

  // Delete audio file
  static Future<int> deleteAudio(int id) async {
    return await _dbHelper.deleteAudio(id);
  }

  // Get audio count
  static Future<int> getAudioCount() async {
    return await _dbHelper.getAudioCount();
  }

  // Get audio count by mood
  static Future<int> getAudioByMoodCount(String mood) async {
    return await _dbHelper.getAudioByMoodCount(mood);
  }

  // Get popular moods (moods with most audio files)
  static Future<List<Map<String, dynamic>>> getPopularMoods() async {
    // This would require a more complex query in the database helper
    // For now, we'll get all audio and group by mood in memory
    final allAudio = await getAllAudio();
    final moodCounts = <String, int>{};
    
    for (final audio in allAudio) {
      final mood = audio['mood'] as String;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMoods.map((entry) => {
      'mood': entry.key,
      'count': entry.value,
    }).toList();
  }

  // Search audio by name or text
  static Future<List<Map<String, dynamic>>> searchAudio(String query) async {
    final allAudio = await getAllAudio();
    final results = <Map<String, dynamic>>[];

    for (final audio in allAudio) {
      final name = audio['name']?.toString().toLowerCase() ?? '';
      final text = audio['text']?.toString().toLowerCase() ?? '';
      final mood = audio['mood']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      if (name.contains(searchQuery) || 
          text.contains(searchQuery) || 
          mood.contains(searchQuery)) {
        results.add(audio);
      }
    }

    return results;
  }

  // Get recent audio files
  static Future<List<Map<String, dynamic>>> getRecentAudio({int limit = 10}) async {
    final allAudio = await getAllAudio();
    if (allAudio.length <= limit) return allAudio;
    return allAudio.take(limit).toList();
  }

  // Get audio files created in a specific date range
  static Future<List<Map<String, dynamic>>> getAudioByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allAudio = await getAllAudio();
    final results = <Map<String, dynamic>>[];

    for (final audio in allAudio) {
      final createdAt = DateTime.parse(audio['createdAt']);
      if (createdAt.isAfter(startDate) && createdAt.isBefore(endDate)) {
        results.add(audio);
      }
    }

    return results;
  }

  // Clean up orphaned audio files (files that don't exist on disk)
  static Future<List<int>> findOrphanedAudio() async {
    // This would require file system access to check if files exist
    // For now, return empty list
    return [];
  }

  // Get audio statistics
  static Future<Map<String, dynamic>> getAudioStats() async {
    final totalCount = await getAudioCount();
    final allAudio = await getAllAudio();
    
    final moodCounts = <String, int>{};

    for (final audio in allAudio) {
      final mood = audio['mood'] as String;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final mostPopularMood = moodCounts.isEmpty 
        ? null 
        : moodCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    return {
      'totalCount': totalCount,
      'uniqueMoods': moodCounts.length,
      'mostPopularMood': mostPopularMood,
      'moodDistribution': moodCounts,
    };
  }
} 