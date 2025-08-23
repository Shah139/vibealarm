class AudioFile {
  final int? id;
  final String? name;
  final String? text;
  final String mood;
  final String localPath;
  final DateTime createdAt;
  final String? voiceName;
  final double? pitch;
  final double? speed;
  final String? languageCode;
  final int? duration; // in seconds
  final String? fileSize; // in bytes
  final bool isGenerated; // true for AI-generated, false for pre-installed

  AudioFile({
    this.id,
    this.name,
    this.text,
    required this.mood,
    required this.localPath,
    required this.createdAt,
    this.voiceName,
    this.pitch,
    this.speed,
    this.languageCode,
    this.duration,
    this.fileSize,
    this.isGenerated = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'text': text,
      'mood': mood,
      'localPath': localPath,
      'createdAt': createdAt.toIso8601String(),
      'voiceName': voiceName,
      'pitch': pitch,
      'speed': speed,
      'languageCode': languageCode,
      'duration': duration,
      'fileSize': fileSize,
      'isGenerated': isGenerated ? 1 : 0,
    };
  }

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'],
      name: json['name'],
      text: json['text'],
      mood: json['mood'],
      localPath: json['localPath'],
      createdAt: DateTime.parse(json['createdAt']),
      voiceName: json['voiceName'],
      pitch: json['pitch']?.toDouble(),
      speed: json['speed']?.toDouble(),
      languageCode: json['languageCode'],
      duration: json['duration'],
      fileSize: json['fileSize'],
      isGenerated: json['isGenerated'] == 1,
    );
  }

  AudioFile copyWith({
    int? id,
    String? name,
    String? text,
    String? mood,
    String? localPath,
    DateTime? createdAt,
    String? voiceName,
    double? pitch,
    double? speed,
    String? languageCode,
    int? duration,
    String? fileSize,
    bool? isGenerated,
  }) {
    return AudioFile(
      id: id ?? this.id,
      name: name ?? this.name,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      voiceName: voiceName ?? this.voiceName,
      pitch: pitch ?? this.pitch,
      speed: speed ?? this.speed,
      languageCode: languageCode ?? this.languageCode,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  @override
  String toString() {
    return 'AudioFile(id: $id, name: $name, mood: $mood, localPath: $localPath, isGenerated: $isGenerated)';
  }
} 