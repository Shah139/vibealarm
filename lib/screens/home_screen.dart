import 'package:flutter/material.dart';
import 'audio_library_screen.dart';
import 'create_alarm_screen.dart';
import 'burst_alarm_screen.dart';
import 'edit_alarm_screen.dart';
import 'database_viewer_screen.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Alarm> _upcomingAlarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final alarms = await AlarmService.getAllAlarms();
      setState(() {
        _upcomingAlarms = alarms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error if needed
    }
  }

  Future<void> _refreshAlarms() async {
    await _loadAlarms();
  }

  Future<void> _editAlarm(Alarm alarm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAlarmScreen(alarm: alarm),
      ),
    );
    _loadAlarms(); // Refresh alarms when returning
  }

  Future<bool> _showDeleteConfirmation(Alarm alarm) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Alarm'),
          content: Text(
            'Are you sure you want to delete the alarm set for ${alarm.time} ${alarm.period}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VibeAlarm',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAlarms,
            tooltip: 'Refresh Alarms',
          ),
          IconButton(
            icon: const Icon(Icons.library_music),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AudioLibraryScreen(),
                ),
              );
            },
            tooltip: 'Audio Library',
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseViewerScreen(),
                ),
              );
            },
            tooltip: 'Database Viewer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                const Text(
                  'Upcoming Alarms',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Long press to edit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_upcomingAlarms.where((alarm) => alarm.isActive).length} active alarms',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 24),

            // Alarms list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A90E2),
                      ),
                    )
                  : _upcomingAlarms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.alarm_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No alarms set yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first alarm to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _upcomingAlarms.length,
                          itemBuilder: (context, index) {
                            final alarm = _upcomingAlarms[index];
                            return Dismissible(
                              key: Key(alarm.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await _showDeleteConfirmation(alarm);
                              },
                              onDismissed: (direction) async {
                                await AlarmService.deleteAlarm(alarm.id);
                                _loadAlarms();
                              },
                              child: GestureDetector(
                                onLongPress: () => _editAlarm(alarm),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Time display
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  alarm.time,
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  alarm.period,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Frequency and tune name in same row
                                            Row(
                                              children: [
                                                Text(
                                                  alarm.frequency,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  alarm.audio,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Show burst alarm indicator if applicable
                                            if (alarm.isBurstAlarm && alarm.burstAlarmTimes != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.burst_mode,
                                                      size: 12,
                                                      color: Colors.orange[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Burst Alarm',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.orange[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const Spacer(),

                                        // Edit button
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () => _editAlarm(alarm),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.edit,
                                                  color: Color(0xFF4A90E2),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Square toggle button
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: alarm.isActive 
                                                ? const Color(0xFF4A90E2).withValues(alpha: 0.2)  // Faded blue when ON
                                                : Colors.grey[100], // Light grey when OFF
                                            border: Border.all(
                                              color: alarm.isActive 
                                                  ? const Color(0xFF4A90E2)  // Blue border when ON
                                                  : Colors.grey[300]!, // Grey border when OFF
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                await AlarmService.toggleAlarm(alarm.id);
                                                _loadAlarms(); // Refresh the list
                                              },
                                              child: Center(
                                                child: Icon(
                                                  Icons.check,
                                                  color: alarm.isActive 
                                                      ? const Color(0xFF4A90E2)  // Blue check when ON
                                                      : Colors.grey[400], // Grey check when OFF
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Quick action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.alarm,
                    title: 'Create',
                    subtitle: 'Alarm',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAlarmScreen(),
                        ),
                      );
                      _loadAlarms(); // Refresh alarms when returning
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.warning,
                    title: 'Burst',
                    subtitle: 'Alarm',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BurstAlarmScreen(),
                        ),
                      );
                      _loadAlarms(); // Refresh alarms when returning
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 