import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/alarm.dart';

class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Alarm> _alarms = [];
  List<Map<String, dynamic>> _burstGroups = [];
  List<Map<String, dynamic>> _audioLibrary = [];
  List<Map<String, dynamic>> _audio = [];
  // List<Map<String, dynamic>> _alarmHistory = []; // Will be used for future alarm history features
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
              final alarms = await _dbHelper.getAllAlarms();
        final burstGroups = await _dbHelper.getBurstAlarmGroups();
        final audioLibrary = await _dbHelper.getAudioLibrary();
        final audio = await _dbHelper.getAllAudio();
        
        setState(() {
          _alarms = alarms;
          _burstGroups = burstGroups;
          _audioLibrary = audioLibrary;
          _audio = audio;
          _isLoading = false;
        });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database Viewer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
            ),
          ],
                  bottom: const TabBar(
          tabs: [
            Tab(text: 'Alarms'),
            Tab(text: 'Burst Groups'),
            Tab(text: 'Audio'),
            Tab(text: 'Audio Library'),
            Tab(text: 'Stats'),
          ],
        ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
            children: [
              _buildAlarmsTab(),
              _buildBurstGroupsTab(),
              _buildAudioTab(),
              _buildAudioLibraryTab(),
              _buildStatsTab(),
            ],
          ),
      ),
    );
  }

  Widget _buildAlarmsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${alarm.time} ${alarm.period}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: alarm.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alarm.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Frequency: ${alarm.frequency}'),
                Text('Audio: ${alarm.audio}'),
                if (alarm.mood != null) Text('Mood: ${alarm.mood}'),
                if (alarm.message != null) Text('Message: ${alarm.message}'),
                Text('Created: ${alarm.createdAt.toString().substring(0, 16)}'),
                if (alarm.isBurstAlarm) 
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Burst Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBurstGroupsTab() {
    if (_burstGroups.isEmpty) {
      return const Center(
        child: Text('No burst alarm groups found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _burstGroups.length,
      itemBuilder: (context, index) {
        final group = _burstGroups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Start: ${group['startTime']}'),
                Text('End: ${group['endTime']}'),
                Text('Total Alarms: ${group['totalAlarms']}'),
                Text('Audio: ${group['audio']}'),
                Text('Frequency: ${group['frequency']}'),
                Text('Created: ${group['createdAt'].toString().substring(0, 16)}'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: group['isActive'] == 1 ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    group['isActive'] == 1 ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioTab() {
    if (_audio.isEmpty) {
      return const Center(
        child: Text('No AI-generated or custom audio files found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _audio.length,
      itemBuilder: (context, index) {
        final audio = _audio[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio['name'] ?? 'Unnamed Audio',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Mood: ${audio['mood']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${audio['id']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (audio['text'] != null) ...[
                  Text(
                    'Original Text:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      audio['text'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('File Path: ${audio['localPath']}'),
                Text('Created: ${audio['createdAt'].toString().substring(0, 16)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioLibraryTab() {
    if (_audioLibrary.isEmpty) {
      return const Center(
        child: Text('No audio files found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _audioLibrary.length,
      itemBuilder: (context, index) {
        final audio = _audioLibrary[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(audio['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${audio['category']}'),
                Text('Type: ${audio['isCustom'] == 1 ? 'Custom' : 'Pre-installed'}'),
                if (audio['duration'] != null) Text('Duration: ${audio['duration']}s'),
              ],
            ),
            trailing: Text(
              audio['createdAt'].toString().substring(0, 10),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<Map<String, int>>(
      future: _getStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard('Total Alarms', stats['totalAlarms'] ?? 0, Icons.alarm),
              const SizedBox(height: 16),
              _buildStatCard('Active Alarms', stats['activeAlarms'] ?? 0, Icons.check_circle),
              const SizedBox(height: 16),
              _buildStatCard('Burst Alarms', stats['burstAlarms'] ?? 0, Icons.burst_mode),
              const SizedBox(height: 16),
              _buildStatCard('AI/Custom Audio', stats['aiAudioFiles'] ?? 0, Icons.music_note),
              const SizedBox(height: 16),
              _buildStatCard('Pre-installed Audio', stats['preInstalledAudio'] ?? 0, Icons.library_music),
              const SizedBox(height: 32),
              const Text(
                'Database Tables',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTableInfo('alarms', 'Main alarms table with all alarm data'),
              _buildTableInfo('burst_alarm_groups', 'Burst alarm group management'),
              _buildTableInfo('audio', 'AI-generated and custom audio files'),
              _buildTableInfo('alarm_history', 'Alarm trigger history and snooze data'),
              _buildTableInfo('audio_library', 'Pre-installed audio files'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4A90E2),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableInfo(String tableName, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tableName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getStats() async {
    try {
      final totalAlarms = await _dbHelper.getAlarmCount();
      final activeAlarms = await _dbHelper.getActiveAlarmCount();
      final burstAlarms = _alarms.where((alarm) => alarm.isBurstAlarm).length;
      final aiAudioFiles = _audio.length;
      final preInstalledAudio = _audioLibrary.length;

      return {
        'totalAlarms': totalAlarms,
        'activeAlarms': activeAlarms,
        'burstAlarms': burstAlarms,
        'aiAudioFiles': aiAudioFiles,
        'preInstalledAudio': preInstalledAudio,
      };
    } catch (e) {
      return {};
    }
  }
} 