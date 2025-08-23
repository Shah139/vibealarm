class VoiceConfig {
  final String mood;
  final String voiceName;
  final double pitch;
  final double speed;
  final String languageCode;
  final String displayName;
  final String description;

  const VoiceConfig({
    required this.mood,
    required this.voiceName,
    required this.pitch,
    required this.speed,
    required this.languageCode,
    required this.displayName,
    required this.description,
  });

  // Predefined voice configurations for different moods
  static const List<VoiceConfig> availableVoices = [
    // English Voices
    VoiceConfig(
      mood: 'Energetic',
      voiceName: 'en-US-Wavenet-D',
      pitch: 1.3,
      speed: 1.0,
      languageCode: 'en-US',
      displayName: 'Energetic Voice',
      description: 'High energy, motivating tone',
    ),
    VoiceConfig(
      mood: 'Calm',
      voiceName: 'en-US-Wavenet-A',
      pitch: 0.9,
      speed: 0.6,
      languageCode: 'en-US',
      displayName: 'Calm Voice',
      description: 'Soft, soothing tone',
    ),
    VoiceConfig(
      mood: 'Romantic',
      voiceName: 'en-US-Wavenet-F',
      pitch: 1.0,
      speed: 0.8,
      languageCode: 'en-US',
      displayName: 'Romantic Voice',
      description: 'Warm, affectionate tone',
    ),
    VoiceConfig(
      mood: 'Funny',
      voiceName: 'en-US-Wavenet-C',
      pitch: 1.5,
      speed: 1.2,
      languageCode: 'en-US',
      displayName: 'Funny Voice',
      description: 'Playful, humorous tone',
    ),
    VoiceConfig(
      mood: 'Focused',
      voiceName: 'en-US-Wavenet-E',
      pitch: 1.1,
      speed: 0.9,
      languageCode: 'en-US',
      displayName: 'Focused Voice',
      description: 'Clear, attentive tone',
    ),
    VoiceConfig(
      mood: 'Relaxed',
      voiceName: 'en-US-Wavenet-B',
      pitch: 0.8,
      speed: 0.7,
      languageCode: 'en-US',
      displayName: 'Relaxed Voice',
      description: 'Gentle, peaceful tone',
    ),
    VoiceConfig(
      mood: 'Motivated',
      voiceName: 'en-US-Wavenet-G',
      pitch: 1.2,
      speed: 1.1,
      languageCode: 'en-US',
      displayName: 'Motivated Voice',
      description: 'Confident, inspiring tone',
    ),
    VoiceConfig(
      mood: 'Peaceful',
      voiceName: 'en-US-Wavenet-H',
      pitch: 0.7,
      speed: 0.5,
      languageCode: 'en-US',
      displayName: 'Peaceful Voice',
      description: 'Tranquil, meditative tone',
    ),
    VoiceConfig(
      mood: 'Productive',
      voiceName: 'en-US-Wavenet-I',
      pitch: 1.0,
      speed: 1.0,
      languageCode: 'en-US',
      displayName: 'Productive Voice',
      description: 'Efficient, task-oriented tone',
    ),
    VoiceConfig(
      mood: 'Creative',
      voiceName: 'en-US-Wavenet-J',
      pitch: 1.4,
      speed: 0.8,
      languageCode: 'en-US',
      displayName: 'Creative Voice',
      description: 'Imaginative, artistic tone',
    ),
    
    // Bangla Voices (if available in Google TTS)
    VoiceConfig(
      mood: 'Energetic',
      voiceName: 'bn-IN-Wavenet-A',
      pitch: 1.3,
      speed: 1.0,
      languageCode: 'bn-IN',
      displayName: 'Energetic Bangla',
      description: 'High energy in Bangla',
    ),
    VoiceConfig(
      mood: 'Calm',
      voiceName: 'bn-IN-Wavenet-B',
      pitch: 0.9,
      speed: 0.6,
      languageCode: 'bn-IN',
      displayName: 'Calm Bangla',
      description: 'Soft, soothing Bangla',
    ),
  ];

  // Get voice configuration by mood and language
  static VoiceConfig? getVoiceByMoodAndLanguage(String mood, String languageCode) {
    try {
      return availableVoices.firstWhere(
        (voice) => voice.mood == mood && voice.languageCode == languageCode,
      );
    } catch (e) {
      // Fallback to English if specific language not found
      return availableVoices.firstWhere(
        (voice) => voice.mood == mood && voice.languageCode == 'en-US',
      );
    }
  }

  // Get all available moods
  static List<String> getAvailableMoods() {
    return availableVoices.map((voice) => voice.mood).toSet().toList();
  }

  // Get all available languages
  static List<String> getAvailableLanguages() {
    return availableVoices.map((voice) => voice.languageCode).toSet().toList();
  }

  // Get voices by language
  static List<VoiceConfig> getVoicesByLanguage(String languageCode) {
    return availableVoices.where((voice) => voice.languageCode == languageCode).toList();
  }

  @override
  String toString() {
    return 'VoiceConfig(mood: $mood, voiceName: $voiceName, languageCode: $languageCode)';
  }
} 