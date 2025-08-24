import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../models/audio_file.dart';
import '../models/voice_config.dart';
import '../services/alarm_service.dart';
import '../services/tts_service.dart';
import '../services/audio_player_service.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  // Selected options
  String _selectedMood = 'Energetic';
  String _selectedFrequency = 'Once';
  String _selectedLanguage = 'en-US';
  
  // Available options
  final List<String> _moodOptions = VoiceConfig.getAvailableMoods();
  final List<String> _languageOptions = ['en-US', 'bn-IN'];
  final TextEditingController _messageController = TextEditingController();
  bool _isGeneratingAudio = false;
  bool _audioGenerated = false;
  AudioFile? _generatedAudio;
  String? _errorMessage;

  // Services
  final TTSService _ttsService = TTSService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Alarm',
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
            // Time Picker Section
            _buildSectionHeader('Set Time', Icons.access_time),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 32),

            // Mood Selection Section
            _buildSectionHeader('Choose Mood & Language', Icons.mood),
            const SizedBox(height: 16),
            _buildMoodDropdown(),
            const SizedBox(height: 16),
            _buildLanguageDropdown(),
            
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

            // Generate Audio Section
            _buildSectionHeader('Generate Audio', Icons.music_note),
            const SizedBox(height: 16),
            
            // Helpful info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF4A90E2),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure you have entered a message (minimum 3 characters) before generating audio. The audio will be created using Google Cloud TTS with your selected mood and language.',
                      style: TextStyle(
                        color: const Color(0xFF2C3E50),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            _buildAudioGeneration(),
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
                  'Save Alarm',
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

  Widget _buildTimePicker() {
    return Card(
      child: InkWell(
        onTap: _selectTime,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF4A90E2),
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMoodDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedMood,
          decoration: InputDecoration(
            labelText: 'Mood',
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
          items: _moodOptions.map((mood) {
            return DropdownMenuItem(
              value: mood,
              child: Text(mood),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMood = value;
              });
            }
          },
            ),
          ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            labelText: 'Language',
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
          items: _languageOptions.map((language) {
            final isSelected = _selectedLanguage == language;
            final displayName = language == 'en-US' ? 'English' : 'বাংলা (Bangla)';
            return DropdownMenuItem(
              value: language,
              child: Text(displayName),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLanguage = value;
              });
            }
          },
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

  Widget _buildMessageInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
          controller: _messageController,
          maxLines: 3,
              maxLength: 100,
          decoration: InputDecoration(
                hintText: 'Enter your custom alarm message... (minimum 3 characters)',
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
                counterText: '${_messageController.text.length}/100 characters',
                counterStyle: TextStyle(
                  color: _messageController.text.length < 3 ? Colors.red : Colors.grey[600],
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // Trigger rebuild to update counter and validation
                });
              },
            ),
            if (_messageController.text.isNotEmpty && _messageController.text.length < 3) ...[
              const SizedBox(height: 8),
              Text(
                'Message must be at least 3 characters long',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioGeneration() {
    return Column(
      children: [
        // Generate Audio Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _canGenerateAudio() ? (_isGeneratingAudio ? null : _generateAudio) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getAudioButtonColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _getAudioButtonIcon(),
            label: Text(
              _getAudioButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Error Message Display
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                        'Audio Generation Failed',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red[600]),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tips: Ensure your message is at least 3 characters long and check your internet connection.',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showTroubleshootingTips,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A90E2),
                      side: const BorderSide(color: Color(0xFF4A90E2)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('View Troubleshooting Tips'),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Generated Audio Preview
        if (_audioGenerated) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.music_note,
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
                              _generatedAudio?.name ?? 'Generated Audio',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${_generatedAudio?.mood ?? _selectedMood} mood • ${_generatedAudio?.languageCode ?? _selectedLanguage}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                            if (_generatedAudio?.duration != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Duration: ${_generatedAudio!.duration!}s',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF95A5A6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _previewAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _regenerateAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF95A5A6),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
    final messageText = _messageController.text.trim();
    
    // Enhanced validation
    if (messageText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a message to generate audio';
      });
      return;
    }
    
    if (messageText.length < 3) {
      setState(() {
        _errorMessage = 'Message must be at least 3 characters long';
      });
      return;
    }

    setState(() {
      _isGeneratingAudio = true;
      _errorMessage = null;
    });

    try {
      // Generate audio using TTS service
      final audioFile = await _ttsService.generateAudio(
        text: messageText,
        mood: _selectedMood,
        languageCode: _selectedLanguage,
      );

      setState(() {
        _isGeneratingAudio = false;
        _audioGenerated = true;
        _generatedAudio = audioFile;
      });
    } catch (e) {
      setState(() {
        _isGeneratingAudio = false;
        // Provide more specific error messages based on the error type
        if (e.toString().contains('RangeError')) {
          _errorMessage = 'Failed to generate audio: Invalid text length. Please try a different message.';
        } else if (e.toString().contains('Failed to save audio file')) {
          _errorMessage = 'Failed to save audio file. Please check storage permissions and try again.';
        } else if (e.toString().contains('TTS API failed')) {
          _errorMessage = 'TTS service temporarily unavailable. Please try again later.';
        } else {
          _errorMessage = 'Failed to generate audio: ${e.toString().replaceAll('Exception: ', '')}';
        }
      });
    }
  }

  void _previewAudio() async {
    if (_generatedAudio == null) return;

    try {
      // Initialize audio player if not already done
      await _audioPlayer.initialize();
      
      // Preview the audio directly without showing dialog
      await _audioPlayer.previewAudio(_generatedAudio!);
      
      // Show a simple success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: ${_generatedAudio!.name ?? 'Generated Audio'}'),
            duration: const Duration(seconds: 2),
                ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to preview audio: $e')),
        );
      }
    }
  }

  /// Show troubleshooting tips dialog
  void _showTroubleshootingTips() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Troubleshooting Tips'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you\'re having trouble generating audio, try these steps:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildTipItem('1', 'Ensure your message is at least 3 characters long'),
              _buildTipItem('2', 'Check your internet connection'),
              _buildTipItem('3', 'Verify the app has storage permissions'),
              _buildTipItem('4', 'Try using a different message or mood'),
              _buildTipItem('5', 'Restart the app if issues persist'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipItem(String number, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _regenerateAudio() {
    setState(() {
      _audioGenerated = false;
      _generatedAudio = null;
      _errorMessage = null;
    });
  }

  bool _canSave() {
    final messageText = _messageController.text.trim();
    return messageText.isNotEmpty && 
           messageText.length >= 3 && 
           _audioGenerated;
  }

  bool _canGenerateAudio() {
    final messageText = _messageController.text.trim();
    return messageText.isNotEmpty && 
           messageText.length >= 3 && 
           !_isGeneratingAudio;
  }

  Color _getAudioButtonColor() {
    if (_isGeneratingAudio) {
      return Colors.grey[400]!;
    } else if (_audioGenerated) {
      return const Color(0xFF27AE60);
    } else if (_canGenerateAudio()) {
      return const Color(0xFF4A90E2);
    } else {
      return Colors.grey[400]!;
    }
  }

  Widget _getAudioButtonIcon() {
    if (_isGeneratingAudio) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (_audioGenerated) {
      return const Icon(Icons.check);
    } else {
      return const Icon(Icons.music_note);
    }
  }

  String _getAudioButtonText() {
    if (_isGeneratingAudio) {
      return 'Generating...';
    } else if (_audioGenerated) {
      return 'Audio Generated';
    } else if (_canGenerateAudio()) {
      return 'Generate Audio';
    } else {
      return 'Enter Message (min 3 chars)';
    }
  }

  void _saveAlarm() async {
    if (_generatedAudio == null) {
      setState(() {
        _errorMessage = 'Please generate audio before saving the alarm';
      });
      return;
    }

    try {
      // Create the alarm
      final alarm = Alarm(
        id: AlarmService.generateId(),
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        period: _selectedTime.hour < 12 ? 'AM' : 'PM',
        frequency: _selectedFrequency,
        audio: _generatedAudio!.localPath, // Use the local path of generated audio
        audioName: _generatedAudio!.name ?? 'Generated Audio', // Use the generated audio name with fallback
        isActive: true,
        message: _messageController.text.trim(),
        mood: _selectedMood,
        createdAt: DateTime.now(),
      );

      // Save the alarm
      await AlarmService.addAlarm(alarm);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Alarm Created!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your alarm has been set for ${_selectedTime.format(context)} with the mood "$_selectedMood".',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Audio: ${_generatedAudio!.name ?? 'Generated Audio'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ],
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save alarm: $e';
      });
    }
  }
} 