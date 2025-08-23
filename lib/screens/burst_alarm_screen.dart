import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class BurstAlarmScreen extends StatefulWidget {
  const BurstAlarmScreen({super.key});

  @override
  State<BurstAlarmScreen> createState() => _BurstAlarmScreenState();
}

class _BurstAlarmScreenState extends State<BurstAlarmScreen> {
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  int _totalAlarms = 5;
  String _selectedAudio = 'Morning Vibes';
  String _selectedFrequency = 'Once';
  bool _isScheduling = false;

  final List<Map<String, dynamic>> _audioOptions = [
    {'name': 'Morning Vibes', 'type': 'Pre-installed', 'category': 'Energetic'},
    {'name': 'Focus Mode', 'type': 'Pre-installed', 'category': 'Productive'},
    {'name': 'Chill Beats', 'type': 'Pre-installed', 'category': 'Relaxed'},
    {'name': 'Custom Meditation', 'type': 'Generated', 'category': 'Calm'},
    {'name': 'Study Session', 'type': 'Generated', 'category': 'Focused'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Burst Alarm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Multiple Alarms',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a series of alarms within a time range',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Time Range', Icons.schedule),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTimePicker('Start Time', _startTime, _selectStartTime)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('End Time', _endTime, _selectEndTime)),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Alarm Count', Icons.alarm),
            const SizedBox(height: 16),
            _buildAlarmCountSelector(),
            const SizedBox(height: 32),

            _buildSectionHeader('Choose Audio', Icons.music_note),
            const SizedBox(height: 16),
            _buildAudioSelector(),
            const SizedBox(height: 32),

            _buildSectionHeader('Frequency', Icons.repeat),
            const SizedBox(height: 16),
            _buildFrequencySelector(),
            const SizedBox(height: 32),

            _buildSectionHeader('Preview', Icons.visibility),
            const SizedBox(height: 16),
            _buildPreviewSection(),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSchedule() ? _scheduleAlarms : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isScheduling
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Scheduling...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Schedule Alarms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4A90E2),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function() onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time.format(context),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.access_time,
                color: const Color(0xFF4A90E2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmCountSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  color: const Color(0xFF4A90E2),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Alarms',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$_totalAlarms alarms',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _totalAlarms > 2 ? _decreaseAlarmCount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF95A5A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _totalAlarms < 20 ? _increaseAlarmCount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAudio,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          _audioOptions.firstWhere((audio) => audio['name'] == _selectedAudio)['type'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF4A90E2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            ..._audioOptions.map((audio) => _buildAudioOption(audio)),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedFrequency,
          decoration: InputDecoration(
            labelText: 'Repeat',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
          ),
          items: AlarmService.getFrequencyOptions().map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(frequency),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFrequency = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAudioOption(Map<String, dynamic> audio) {
    final isSelected = audio['name'] == _selectedAudio;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAudio = audio['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.music_note,
              color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF4A90E2) : const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    '${audio['type']} • ${audio['category']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final timeDifference = _endTime.hour * 60 + _endTime.minute - (_startTime.hour * 60 + _startTime.minute);
    final intervalMinutes = timeDifference > 0 ? (timeDifference / (_totalAlarms - 1)).round() : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF4A90E2),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Schedule Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewRow('Start Time', _startTime.format(context)),
            _buildPreviewRow('End Time', _endTime.format(context)),
            _buildPreviewRow('Total Alarms', '$_totalAlarms'),
            _buildPreviewRow('Interval', '$intervalMinutes minutes'),
            _buildPreviewRow('Audio', _selectedAudio),
            
            if (timeDifference <= 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE57373)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Color(0xFFE57373),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'End time must be after start time',
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime.hour * 60 + _endTime.minute <= _startTime.hour * 60 + _startTime.minute) {
          _endTime = _startTime.replacing(hour: _startTime.hour + 1);
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _increaseAlarmCount() {
    setState(() {
      _totalAlarms++;
    });
  }

  void _decreaseAlarmCount() {
    setState(() {
      _totalAlarms--;
    });
  }

  bool _canSchedule() {
    final timeDifference = _endTime.hour * 60 + _endTime.minute - (_startTime.hour * 60 + _startTime.minute);
    return timeDifference > 0 && _totalAlarms >= 2;
  }

  void _scheduleAlarms() async {
    setState(() {
      _isScheduling = true;
    });

    // Calculate time intervals
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final interval = (endMinutes - startMinutes) / (_totalAlarms - 1);

    // Create burst alarms
    for (int i = 0; i < _totalAlarms; i++) {
      final alarmMinutes = startMinutes + (interval * i);
      final alarmHour = (alarmMinutes ~/ 60) % 24;
      final alarmMinute = (alarmMinutes % 60).round();
      
      final alarm = Alarm(
        id: AlarmService.generateId(),
        time: '${alarmHour.toString().padLeft(2, '0')}:${alarmMinute.toString().padLeft(2, '0')}',
        period: alarmHour < 12 ? 'AM' : 'PM',
        frequency: _selectedFrequency,
        audio: _selectedAudio,
        isActive: true,
        createdAt: DateTime.now(),
        isBurstAlarm: true,
        burstAlarmTimes: List.generate(_totalAlarms, (index) {
          final burstMinutes = startMinutes + (interval * index);
          final burstHour = (burstMinutes ~/ 60) % 24;
          final burstMinute = (burstMinutes % 60).round();
          return '${burstHour.toString().padLeft(2, '0')}:${burstMinute.toString().padLeft(2, '0')}';
        }),
      );

      await AlarmService.addAlarm(alarm);
    }

    setState(() {
      _isScheduling = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alarms Scheduled!'),
            content: Text(
              'Successfully scheduled $_totalAlarms alarms from ${_startTime.format(context)} to ${_endTime.format(context)} using "$_selectedAudio".',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Great!'),
              ),
            ],
          );
        },
      );
    }
  }
} 