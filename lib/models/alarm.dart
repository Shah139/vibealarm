class Alarm {
  final String id;
  final String time;
  final String period;
  final String frequency;
  final String audio;
  final String audioName; // Added field for audio display name
  final bool isActive;
  final String? message;
  final String? mood;
  final DateTime createdAt;
  final bool isBurstAlarm;
  final List<String>? burstAlarmTimes;
  
  // New fields for alarm scheduling
  final DateTime? nextTriggerTime;
  final DateTime? lastTriggered;
  final bool isScheduled;

  Alarm({
    required this.id,
    required this.time,
    required this.period,
    required this.frequency,
    required this.audio,
    required this.audioName, // Added to required parameters
    required this.isActive,
    this.message,
    this.mood,
    required this.createdAt,
    this.isBurstAlarm = false,
    this.burstAlarmTimes,
    this.nextTriggerTime,
    this.lastTriggered,
    this.isScheduled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'period': period,
      'frequency': frequency,
      'audio': audio,
      'audioName': audioName, // Added to JSON serialization
      'isActive': isActive,
      'message': message,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
      'isBurstAlarm': isBurstAlarm,
      'burstAlarmTimes': burstAlarmTimes,
      'nextTriggerTime': nextTriggerTime?.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'isScheduled': isScheduled ? 1 : 0,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: json['time'],
      period: json['period'],
      frequency: json['frequency'],
      audio: json['audio'],
      audioName: json['audioName'] ?? 'Unknown Audio', // Added with fallback
      isActive: json['isActive'],
      message: json['message'],
      mood: json['mood'],
      createdAt: DateTime.parse(json['createdAt']),
      isBurstAlarm: json['isBurstAlarm'] ?? false,
      burstAlarmTimes: json['burstAlarmTimes'] != null 
          ? List<String>.from(json['burstAlarmTimes'])
          : null,
      nextTriggerTime: json['nextTriggerTime'] != null 
          ? DateTime.parse(json['nextTriggerTime'])
          : null,
      lastTriggered: json['lastTriggered'] != null 
          ? DateTime.parse(json['lastTriggered'])
          : null,
      isScheduled: json['isScheduled'] == 1,
    );
  }

  Alarm copyWith({
    String? id,
    String? time,
    String? period,
    String? frequency,
    String? audio,
    String? audioName, // Added to copyWith parameters
    bool? isActive,
    String? message,
    String? mood,
    DateTime? createdAt,
    bool? isBurstAlarm,
    List<String>? burstAlarmTimes,
    DateTime? nextTriggerTime,
    DateTime? lastTriggered,
    bool? isScheduled,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      period: period ?? this.period,
      frequency: frequency ?? this.frequency,
      audio: audio ?? this.audio,
      audioName: audioName ?? this.audioName, // Added to copyWith
      isActive: isActive ?? this.isActive,
      message: message ?? this.message,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      isBurstAlarm: isBurstAlarm ?? this.isBurstAlarm,
      burstAlarmTimes: burstAlarmTimes ?? this.burstAlarmTimes,
      nextTriggerTime: nextTriggerTime ?? this.nextTriggerTime,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      isScheduled: isScheduled ?? this.isScheduled,
    );
  }
} 