import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../models/audio_file.dart';
import '../services/audio_player_service.dart';

class AudioLibraryScreen extends StatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  bool _isGridView = true;
  bool _isLoading = true;
  List<AudioFile> _audioFiles = [];
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
    _audioPlayer.initialize();
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
      setState(() {
        _audioFiles = allAudio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audio files: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(AudioFile audioFile) async {
    try {
      await _audioPlayer.previewAudio(audioFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
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
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
          ],
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
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
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
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _audioFiles.length,
      itemBuilder: (context, index) {
        final audioFile = _audioFiles[index];
        return _buildAudioCard(audioFile);
      },
    );
  }

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
              
              // Play button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _playAudio(audioFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
            ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play'),
                ),
            ),
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