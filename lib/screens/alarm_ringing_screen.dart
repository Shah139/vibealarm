import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback? onAlarmStopped;

  const AlarmRingingScreen({
    super.key,
    required this.alarm,
    this.onAlarmStopped,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    
    // Keep screen awake
    WakelockPlus.enable();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    print('=== ALARM RINGING SCREEN INITIALIZED ===');
    print('Alarm ID: ${widget.alarm.id}');
    print('Alarm Time: ${widget.alarm.time}');
    print('Alarm Message: ${widget.alarm.message}');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    if (_isStopping) return;
    
    setState(() {
      _isStopping = true;
    });

    try {
      final schedulerService = AlarmSchedulerService();
      await schedulerService.stopAlarmAudio(widget.alarm.id);
      widget.onAlarmStopped?.call();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error stopping alarm: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _snoozeAlarm() async {
    if (_isStopping) return;
    
    try {
      final schedulerService = AlarmSchedulerService();
      await schedulerService.stopAlarmAudio(widget.alarm.id);
      
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozeAlarm = widget.alarm.copyWith(
        id: 'snooze_${widget.alarm.id}',
        time: '${snoozeTime.hour.toString().padLeft(2, '0')}:${snoozeTime.minute.toString().padLeft(2, '0')}',
        period: snoozeTime.hour < 12 ? 'AM' : 'PM',
        message: 'Snooze: ${widget.alarm.message}',
      );
      
      await schedulerService.scheduleAlarm(snoozeAlarm);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm snoozed for 5 minutes'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error snoozing alarm: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from dismissing the alarm
        return false;
      },
      child: Scaffold(
        // Ensure this screen is always on top
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a1a),
                Color(0xFF000000),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Alarm Icon with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alarm,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Current Time
                Text(
                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Alarm Time
                Text(
                  'ALARM: ${widget.alarm.time}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                    fontFamily: 'monospace',
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Alarm Message
                if (widget.alarm.message?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.alarm.message ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 60),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Snooze Button
                    ElevatedButton(
                      onPressed: _isStopping ? null : _snoozeAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'SNOOZE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Stop Button
                    ElevatedButton(
                      onPressed: _isStopping ? null : _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'STOP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Instructions
                const Text(
                  '⚠️ ALARM IS RINGING - USE BUTTONS ABOVE TO CONTROL ⚠️',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 