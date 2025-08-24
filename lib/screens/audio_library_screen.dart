import 'package:flutter/material.dart';
import 'dart:io';
import '../services/tts_service.dart';
import '../models/audio_file.dart';
import '../services/audio_player_service.dart';

class AudioLibraryScreen extends StatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  // bool _isGridView = true; // Removed - always use list view
  bool _isLoading = true;
  List<AudioFile> _audioFiles = [];
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final TTSService _ttsService = TTSService();
  
  // Audio player state
  bool _isPlaying = false;
  AudioFile? _currentlyPlaying;
  double _volume = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      await _audioPlayer.initialize();
      
      // Listen to player state changes
      _audioPlayer.playingStream.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });

      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            if (state.processingState.toString().contains('completed')) {
              _isPlaying = false;
              _currentlyPlaying = null;
            }
          });
        }
      });

      print('Audio player initialized successfully');
    } catch (e) {
      print('Failed to initialize audio player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize audio player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAudioFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allAudio = await _ttsService.getAllAudioFiles();
      
      // Validate audio files
      final validAudioFiles = <AudioFile>[];
      for (final audio in allAudio) {
        try {
          if (audio.localPath.isNotEmpty) {
            final file = File(audio.localPath);
            if (await file.exists()) {
              final fileSize = await file.length();
              if (fileSize > 0) {
                validAudioFiles.add(audio);
                print('Valid audio: ${audio.name} - ${audio.localPath} - ${fileSize} bytes');
              } else {
                print('Invalid audio (0 bytes): ${audio.name} - ${audio.localPath}');
              }
            } else {
              print('Audio file not found: ${audio.name} - ${audio.localPath}');
            }
          } else {
            print('Audio file with empty path: ${audio.name}');
          }
        } catch (e) {
          print('Error validating audio file ${audio.name}: $e');
        }
      }
      
      print('Loaded ${validAudioFiles.length} valid audio files out of ${allAudio.length} total');
      
      setState(() {
        _audioFiles = validAudioFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading audio files: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audio files: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _playAudio(AudioFile audioFile) async {
    try {
      // Validate audio file
      if (audioFile.localPath.isEmpty) {
        throw Exception('Audio file path is empty');
      }

      // Check if file exists
      final file = File(audioFile.localPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: ${audioFile.localPath}');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Audio file is empty (0 bytes)');
      }

      print('Playing audio: ${audioFile.name}');
      print('File path: ${audioFile.localPath}');
      print('File size: $fileSize bytes');

      // Stop current playback if different audio
      if (_currentlyPlaying != audioFile) {
        await _audioPlayer.stop();
        _currentlyPlaying = audioFile;
      }

      // Play the audio
      if (_isPlaying && _currentlyPlaying == audioFile) {
        // If same audio is playing, pause it
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Play the audio
        await _audioPlayer.playAudio(audioFile);
        setState(() {
          _isPlaying = true;
          _currentlyPlaying = audioFile;
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _deleteAudio(AudioFile audioFile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Audio'),
          content: Text('Are you sure you want to delete "${audioFile.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _ttsService.deleteAudioFile(audioFile.id!);
        _loadAudioFiles(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete audio: $e')),
          );
        }
      }
    }
  }

  void _showAudioDetails(AudioFile audioFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(audioFile.name ?? 'Audio Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Text', audioFile.text ?? 'N/A'),
                  _buildDetailRow('Mood', audioFile.mood),
                  _buildDetailRow('Voice', audioFile.voiceName ?? 'Default'),
                  _buildDetailRow('Language', audioFile.languageCode ?? 'en-US'),
                  if (audioFile.duration != null)
                    _buildDetailRow('Duration', '${audioFile.duration}s'),
                  if (audioFile.fileSize != null)
                    _buildDetailRow('File Size', audioFile.fileSize!),
                  _buildDetailRow('Created', _formatDate(audioFile.createdAt)),
                  _buildDetailRow('Type', audioFile.isGenerated ? 'Generated' : 'Pre-installed'),
                  
                  const SizedBox(height: 16),
                  
                  // Volume control
                  Row(
                    children: [
                      const Icon(Icons.volume_down, size: 20),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (value) {
                            setDialogState(() {
                              _volume = value;
                            });
                            _audioPlayer.setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 20),
                      Text('${(_volume * 100).round()}%'),
                    ],
                  ),
                  
                  // Audio controls
                  if (_currentlyPlaying == audioFile) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.resume();
                            }
                            setDialogState(() {});
                          },
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          tooltip: _isPlaying ? 'Pause' : 'Resume',
                        ),
                        IconButton(
                          onPressed: () async {
                            await _audioPlayer.stop();
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.stop),
                          tooltip: 'Stop',
                        ),
                      ],
                    ),
                    
                    // Progress bar
                    if (_totalDuration > Duration.zero) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _currentPosition.inMilliseconds / _totalDuration.inMilliseconds,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _playAudio(audioFile);
                  },
                  icon: Icon(_currentlyPlaying == audioFile && _isPlaying 
                      ? Icons.pause 
                      : Icons.play_arrow),
                  label: Text(_currentlyPlaying == audioFile && _isPlaying 
                      ? 'Pause' 
                      : 'Play'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF7F8C8D)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audio Library',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAudioFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
              ),
            )
          : _audioFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No audio files yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate some audio from the Create Alarm screen',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
          ),
        ],
      ),
                )
              : Column(
                  children: [
                    Expanded(
                      child              : _buildListView(), // Always use list view
                    ),
                    
                    // Global audio controls
                    if (_currentlyPlaying != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Currently playing info
                            Row(
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentlyPlaying!.name ?? 'Unknown Audio',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _currentlyPlaying!.mood,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    if (_isPlaying) {
                                      await _audioPlayer.pause();
                                    } else {
                                      await _audioPlayer.resume();
                                    }
                                  },
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  tooltip: _isPlaying ? 'Pause' : 'Play',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await _audioPlayer.stop();
                                  },
                                  icon: const Icon(Icons.stop),
                                  tooltip: 'Stop',
                                ),
                              ],
                            ),
                            
                            // Progress bar
                            if (_totalDuration > Duration.zero) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _currentPosition.inMilliseconds / _totalDuration.inMilliseconds,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  // Widget _buildGridView() {
  //   return GridView.builder(
  //     padding: const EdgeInsets.all(16),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //       childAspectRatio: 0.8,
  //     ),
  //     itemCount: _audioFiles.length,
  //     itemBuilder: (context, index) {
  //       final audioFile = _audioFiles[index];
  //       return _buildAudioCard(audioFile);
  //       },
  //   );
  // }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _audioFiles.length,
      itemBuilder: (context, index) {
        final audioFile = _audioFiles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAudioCard(audioFile),
        );
      },
    );
  }

  Widget _buildAudioCard(AudioFile audioFile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAudioDetails(audioFile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // Header with mood indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMoodColor(audioFile.mood),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      audioFile.mood,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _deleteAudio(audioFile),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Audio icon and name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(8),
          ),
                    child: const Icon(
            Icons.music_note,
                      color: Color(0xFF4A90E2),
                      size: 20,
          ),
        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      audioFile.name ?? 'Unnamed Audio',
          style: const TextStyle(
                        fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Text preview
              if (audioFile.text != null) ...[
                Text(
                  audioFile.text!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
              ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
            ),
                const SizedBox(height: 8),
              ],
              
              // Play button with state
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _playAudio(audioFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentlyPlaying == audioFile && _isPlaying 
                        ? Colors.orange 
                        : const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    _currentlyPlaying == audioFile && _isPlaying 
                        ? Icons.pause 
                        : Icons.play_arrow, 
                    size: 16
                  ),
                  label: Text(
                    _currentlyPlaying == audioFile && _isPlaying 
                        ? 'Pause' 
                        : 'Play'
                  ),
                ),
              ),
              
              // Volume control for currently playing audio
              if (_currentlyPlaying == audioFile) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.volume_down, size: 16, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 5,
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                          _audioPlayer.setVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 16, color: Colors.grey),
                  ],
                ),
              ],
          ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'energetic':
        return Colors.orange;
      case 'calm':
        return Colors.blue;
      case 'romantic':
        return Colors.pink;
      case 'funny':
        return Colors.yellow.shade700;
      case 'focused':
        return Colors.green;
      case 'relaxed':
        return Colors.teal;
      case 'motivated':
        return Colors.red;
      case 'peaceful':
        return Colors.indigo;
      case 'productive':
        return Colors.purple;
      case 'creative':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
} 