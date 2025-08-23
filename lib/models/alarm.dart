class Alarm {
  final String id;
  final String time;
  final String period;
  final String frequency;
  final String audio;
  final bool isActive;
  final String? message;
  final String? mood;
  final DateTime createdAt;
  final bool isBurstAlarm;
  final List<String>? burstAlarmTimes;

  Alarm({
    required this.id,
    required this.time,
    required this.period,
    required this.frequency,
    required this.audio,
    required this.isActive,
    this.message,
    this.mood,
    required this.createdAt,
    this.isBurstAlarm = false,
    this.burstAlarmTimes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'period': period,
      'frequency': frequency,
      'audio': audio,
      'isActive': isActive,
      'message': message,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
      'isBurstAlarm': isBurstAlarm,
      'burstAlarmTimes': burstAlarmTimes,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: json['time'],
      period: json['period'],
      frequency: json['frequency'],
      audio: json['audio'],
      isActive: json['isActive'],
      message: json['message'],
      mood: json['mood'],
      createdAt: DateTime.parse(json['createdAt']),
      isBurstAlarm: json['isBurstAlarm'] ?? false,
      burstAlarmTimes: json['burstAlarmTimes'] != null 
          ? List<String>.from(json['burstAlarmTimes'])
          : null,
    );
  }

  Alarm copyWith({
    String? id,
    String? time,
    String? period,
    String? frequency,
    String? audio,
    bool? isActive,
    String? message,
    String? mood,
    DateTime? createdAt,
    bool? isBurstAlarm,
    List<String>? burstAlarmTimes,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      period: period ?? this.period,
      frequency: frequency ?? this.frequency,
      audio: audio ?? this.audio,
      isActive: isActive ?? this.isActive,
      message: message ?? this.message,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      isBurstAlarm: isBurstAlarm ?? this.isBurstAlarm,
      burstAlarmTimes: burstAlarmTimes ?? this.burstAlarmTimes,
    );
  }
} 