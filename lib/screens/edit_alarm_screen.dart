import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class EditAlarmScreen extends StatefulWidget {
  final Alarm alarm;
  
  const EditAlarmScreen({super.key, required this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late TimeOfDay _selectedTime;
  // Selected options
  String _selectedMood = 'Energetic';
  String _selectedFrequency = 'Once';
  String _selectedLanguage = 'en-US';
  late final TextEditingController _messageController;
  late bool _isActive;
  bool _isGeneratingAudio = false;
  bool _audioGenerated = false;
  String _generatedAudioName = '';

  final List<String> _moodOptions = [
    'Energetic',
    'Focused',
    'Relaxed',
    'Calm',
    'Motivated',
    'Peaceful',
    'Productive',
    'Creative',
  ];

  @override
  void initState() {
    super.initState();
    // Parse time from alarm
    final timeParts = widget.alarm.time.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    _selectedMood = widget.alarm.mood ?? 'Energetic';
    _selectedFrequency = widget.alarm.frequency;
    _messageController = TextEditingController(text: widget.alarm.message ?? '');
    _isActive = widget.alarm.isActive;
    _generatedAudioName = widget.alarm.audio;
    _audioGenerated = true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Alarm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Alarm',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Picker Section
            _buildSectionHeader('Set Time', Icons.access_time),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 32),

            // Mood Selector Section
            _buildSectionHeader('Choose Mood', Icons.mood),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 32),

            // Frequency Selector Section
            _buildSectionHeader('Frequency', Icons.repeat),
            const SizedBox(height: 16),
            _buildFrequencySelector(),
            const SizedBox(height: 32),

            // Custom Message Section
            _buildSectionHeader('Custom Message', Icons.message),
            const SizedBox(height: 16),
            _buildMessageInput(),
            const SizedBox(height: 32),

            // Audio Section
            _buildSectionHeader('Audio', Icons.music_note),
            const SizedBox(height: 16),
            _buildAudioSection(),
            const SizedBox(height: 32),

            // Active Toggle
            _buildSectionHeader('Status', Icons.toggle_on),
            const SizedBox(height: 16),
            _buildActiveToggle(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSave() ? _saveAlarm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Update Alarm',
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Card(
      child: InkWell(
        onTap: _selectTime,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF4A90E2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF4A90E2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _moodOptions.length,
      itemBuilder: (context, index) {
        final mood = _moodOptions[index];
        final isSelected = mood == _selectedMood;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedMood = mood;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                mood,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
        );
      },
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

  Widget _buildMessageInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your custom alarm message...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A90E2),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _generatedAudioName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_audioGenerated)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingAudio ? null : _generateAudio,
                  icon: _isGeneratingAudio
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.music_note),
                  label: Text(_isGeneratingAudio ? 'Generating...' : 'Generate New Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.toggle_on,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alarm Status',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isActive ? Colors.green[600] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: const Color(0xFF4A90E2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
        _selectedTime = picked;
      });
    }
  }

  void _generateAudio() async {
    setState(() {
      _isGeneratingAudio = true;
    });

    // Simulate audio generation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isGeneratingAudio = false;
      _audioGenerated = true;
      _generatedAudioName = '$_selectedMood Vibes - ${DateTime.now().millisecondsSinceEpoch % 1000}';
    });
  }

  bool _canSave() {
    return _messageController.text.trim().isNotEmpty && _audioGenerated;
  }

  void _saveAlarm() async {
    // Update the existing alarm
    final updatedAlarm = widget.alarm.copyWith(
      time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      period: _selectedTime.hour < 12 ? 'AM' : 'PM',
      frequency: _selectedFrequency,
      audio: _generatedAudioName,
      isActive: _isActive,
      message: _messageController.text.trim(),
      mood: _selectedMood,
    );

    // Update the alarm
    await AlarmService.updateAlarm(updatedAlarm);

    // Show success dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alarm Updated!'),
            content: Text(
              'Your alarm has been updated for ${_selectedTime.format(context)} with the mood "$_selectedMood".',
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Alarm'),
          content: const Text(
            'Are you sure you want to delete this alarm? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAlarm();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlarm() async {
    // Delete the alarm
    await AlarmService.deleteAlarm(widget.alarm.id);

    // Show success dialog and return to previous screen
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alarm Deleted'),
            content: const Text(
              'Your alarm has been successfully deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
} 