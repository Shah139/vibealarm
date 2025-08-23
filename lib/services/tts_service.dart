import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/voice_config.dart';
import '../models/audio_file.dart';
import 'database_helper.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  // Google Cloud TTS API Configuration
  static const String _apiKey = 'AIzaSyBNVyE6RqZryo9uJ4g3WUSkle3IIoyTRGI';
  static const String _baseUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  
  // Cache for generated audio to avoid duplicates
  final Map<String, String> _audioCache = {};
  
  // Database helper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Check if storage is accessible and writable
  Future<bool> _checkStorageAccess() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final testDir = Directory('${appDir.path}/vibealarm_test');
      
      // Try to create a test directory
      if (!await testDir.exists()) {
        await testDir.create(recursive: true);
      }
      
      // Try to create a test file
      final testFile = File('${testDir.path}/test.txt');
      await testFile.writeAsString('test');
      
      // Clean up test files
      await testFile.delete();
      await testDir.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate audio from text and mood using Google Cloud TTS API
  Future<AudioFile> generateAudio({
    required String text,
    required String mood,
    String languageCode = 'en-US',
    String? customName,
  }) async {
    try {
      // Validate input parameters
      if (text.trim().isEmpty) {
        throw Exception('Text cannot be empty');
      }
      
      if (text.trim().length < 3) {
        throw Exception('Text must be at least 3 characters long');
      }

      // Check storage access
      final hasStorageAccess = await _checkStorageAccess();
      if (!hasStorageAccess) {
        throw Exception('Storage access denied. Please check app permissions.');
      }

      // Check cache first
      final cacheKey = '${text}_${mood}_$languageCode';
      if (_audioCache.containsKey(cacheKey)) {
        final cachedPath = _audioCache[cacheKey]!;
        // Verify file still exists
        if (await File(cachedPath).exists()) {
          final cachedAudio = await _getAudioFromPath(cachedPath);
          if (cachedAudio != null) {
            return cachedAudio;
          }
        }
        _audioCache.remove(cacheKey);
      }

      // Get voice configuration for the mood and language
      final voiceConfig = VoiceConfig.getVoiceByMoodAndLanguage(mood, languageCode);
      if (voiceConfig == null) {
        throw Exception('No voice configuration found for mood: $mood and language: $languageCode');
      }

      // Prepare API request
      final requestBody = {
        'input': {
          'text': text,
        },
        'voice': {
          'languageCode': voiceConfig.languageCode,
          'name': voiceConfig.voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'pitch': voiceConfig.pitch,
          'speakingRate': voiceConfig.speed,
          'effectsProfileId': ['headphone-class-device'],
        },
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('TTS API failed: ${response.statusCode} - ${response.body}');
      }

      // Parse response
      final responseData = jsonDecode(response.body);
      final base64Audio = responseData['audioContent'];

      if (base64Audio == null) {
        throw Exception('No audio content received from TTS API');
      }

      // Decode base64 and save to local file
      final audioBytes = base64Decode(base64Audio);
      final localPath = await _saveAudioToLocal(audioBytes, text, mood);

      // Create audio file object
      final audioFile = AudioFile(
        name: customName ?? _generateAudioName(text, mood),
        text: text,
        mood: mood,
        localPath: localPath,
        createdAt: DateTime.now(),
        voiceName: voiceConfig.voiceName,
        pitch: voiceConfig.pitch,
        speed: voiceConfig.speed,
        languageCode: voiceConfig.languageCode,
        duration: _estimateDuration(text, voiceConfig.speed),
        fileSize: audioBytes.length.toString(),
        isGenerated: true,
      );

      // Save to database
      final audioId = await _dbHelper.insertAudio(audioFile.toJson());
      final savedAudioFile = audioFile.copyWith(id: audioId);

      // Cache the result
      _audioCache[cacheKey] = localPath;

      return savedAudioFile;
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('RangeError')) {
        throw Exception('Text processing error: Please try a different message');
      } else if (e.toString().contains('Failed to save audio file')) {
        throw Exception('Storage error: Unable to save audio file. Please check permissions.');
      } else if (e.toString().contains('TTS API failed')) {
        throw Exception('Service error: TTS service is temporarily unavailable. Please try again later.');
      } else if (e.toString().contains('Storage access denied')) {
        throw Exception('Permission error: Please grant storage permissions to the app.');
      } else {
        throw Exception('Failed to generate audio: $e');
      }
    }
  }

  /// Generate audio name from text and mood
  String _generateAudioName(String text, String mood) {
    try {
      // Clean the text and get first 10 characters
      final cleanText = text.trim().replaceAll(RegExp(r'[^\w\s]'), '');
      final displayText = cleanText.length > 10 ? cleanText.substring(0, 10) : cleanText;
      
      // Format: "First 10 chars - Mood"
      return '$displayText - $mood';
    } catch (e) {
      // Fallback name if anything goes wrong
      return '${mood} Audio';
    }
  }

  /// Generate a safe filename from text and mood
  String _generateSafeFilename(String text, String mood) {
    try {
      // Sanitize text: remove special characters and limit length
      final sanitizedText = text
          .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
          .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
          .trim();
      
      // Ensure we have a valid filename
      String safeText;
      if (sanitizedText.isEmpty) {
        safeText = 'message';
      } else if (sanitizedText.length > 20) {
        safeText = sanitizedText.substring(0, 20);
      } else {
        safeText = sanitizedText;
      }
      
      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Create filename
      return '${mood}_$safeText\_$timestamp.mp3';
    } catch (e) {
      // Fallback filename if anything goes wrong
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${mood}_audio\_$timestamp.mp3';
    }
  }

  /// Save audio bytes to local file system
  Future<String> _saveAudioToLocal(List<int> audioBytes, String text, String mood) async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/vibealarm_audio');
      
      // Create audio directory if it doesn't exist
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Generate safe filename
      final filename = _generateSafeFilename(text, mood);
      final filePath = path.join(audioDir.path, filename);

      // Write audio file
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save audio file: $e');
    }
  }

  /// Get audio file from local path
  Future<AudioFile?> _getAudioFromPath(String localPath) async {
    try {
      final allAudio = await _dbHelper.getAllAudio();
      for (final audio in allAudio) {
        if (audio['localPath'] == localPath) {
          return AudioFile.fromJson(audio);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Estimate audio duration based on text length and speaking rate
  int _estimateDuration(String text, double speakingRate) {
    // Rough estimation: average speaking rate is 150 words per minute
    // Adjust based on speaking rate
    final words = text.split(' ').length;
    final baseDuration = (words / 150) * 60; // in seconds
    return (baseDuration / speakingRate).round();
  }

  /// Get all available moods
  List<String> getAvailableMoods() {
    return VoiceConfig.getAvailableMoods();
  }

  /// Get all available languages
  List<String> getAvailableLanguages() {
    return VoiceConfig.getAvailableLanguages();
  }

  /// Get voice configurations for a specific language
  List<VoiceConfig> getVoicesByLanguage(String languageCode) {
    return VoiceConfig.getVoicesByLanguage(languageCode);
  }

  /// Get voice configuration for a specific mood and language
  VoiceConfig? getVoiceConfig(String mood, String languageCode) {
    return VoiceConfig.getVoiceByMoodAndLanguage(mood, languageCode);
  }

  /// Check if audio file exists locally
  Future<bool> audioFileExists(String localPath) async {
    try {
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete audio file from local storage and database
  Future<bool> deleteAudioFile(int audioId) async {
    try {
      // Get audio file from database
      final audio = await _dbHelper.getAudioById(audioId);
      if (audio == null) return false;

      final localPath = audio['localPath'] as String;
      
      // Delete from local storage
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from cache
      _audioCache.removeWhere((key, value) => value == localPath);

      // Delete from database
      await _dbHelper.deleteAudio(audioId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/vibealarm_audio');
      
      if (!await audioDir.exists()) {
        return {
          'totalFiles': 0,
          'totalSize': 0,
          'directoryPath': audioDir.path,
        };
      }

      int totalSize = 0;
      int totalFiles = 0;
      
      await for (final entity in audioDir.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          totalSize += await entity.length();
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'directoryPath': audioDir.path,
        'formattedSize': _formatFileSize(totalSize),
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'directoryPath': 'Error',
        'error': e.toString(),
      };
    }
  }

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear audio cache
  void clearCache() {
    _audioCache.clear();
  }

  /// Get troubleshooting tips for common issues
  List<String> getTroubleshootingTips() {
    return [
      'Ensure your message is at least 3 characters long',
      'Check your internet connection',
      'Verify the app has storage permissions',
      'Try using a different message or mood',
      'Restart the app if issues persist',
    ];
  }

  /// Get all audio files from database
  Future<List<AudioFile>> getAllAudioFiles() async {
    try {
      final allAudio = await _dbHelper.getAllAudio();
      return allAudio.map((audio) => AudioFile.fromJson(audio)).toList();
    } catch (e) {
      throw Exception('Failed to get audio files: $e');
    }
  }

  /// Get cached audio paths
  Map<String, String> getCachedAudioPaths() {
    return Map.from(_audioCache);
  }
} 