import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:vibealarm/screens/home_screen.dart';
import 'package:vibealarm/services/audio_player_service.dart';
import 'package:vibealarm/services/alarm_service.dart';
import 'package:vibealarm/services/alarm_scheduler_service.dart';
import 'package:vibealarm/services/native_alarm_service.dart';
import 'package:vibealarm/screens/alarm_ringing_screen.dart';
import 'package:vibealarm/models/alarm.dart';
import 'package:flutter/services.dart';

// Global navigator key for showing alarm UI from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to show alarm ringing screen from main
void _showAlarmRingingScreenFromMain(Alarm alarm) {
  // Show the alarm ringing screen on top of everything
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => AlarmRingingScreen(
        alarm: alarm,
        onAlarmStopped: () {
          // Stop the alarm audio
          final schedulerService = AlarmService.getSchedulerService();
          if (schedulerService != null) {
            schedulerService.stopAlarmAudio(alarm.id);
          }
        },
      ),
    ),
  );
}

// Function to check for boot restore
void _checkForBootRestore() async {
  try {
    print('Checking for boot restore...');
    
    // Get the alarm service and restore any pending alarms
    final alarmService = AlarmService.getSchedulerService();
    if (alarmService != null) {
      // This will restore alarms from the database and reschedule them
      await alarmService.initialize();
      print('Alarms restored after boot');
    }
  } catch (e) {
    print('Error restoring alarms after boot: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    print('Attempting to load .env file...');
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
    
    // Debug: Check what was loaded
    final apiKey = dotenv.env['GOOGLE_TTS_API_KEY'];
    final baseUrl = dotenv.env['GOOGLE_TTS_BASE_URL'];
    
    print('Loaded GOOGLE_TTS_API_KEY: ${apiKey != null ? '${apiKey.substring(0, 10)}...' : 'NULL'}');
    print('Loaded GOOGLE_TTS_BASE_URL: $baseUrl');
    print('Total environment variables loaded: ${dotenv.env.length}');
    
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print('Make sure you have created a .env file with your API keys');
    print('Current working directory: ${Directory.current.path}');
    
    // List files in current directory to help debug
    try {
      final files = Directory.current.listSync();
      print('Files in current directory:');
      for (final file in files) {
        print('  ${file.path.split('/').last}');
      }
    } catch (listError) {
      print('Could not list directory contents: $listError');
    }
  }
  
  // Initialize alarm scheduler service
  try {
    print('Initializing alarm scheduler service...');
    await AlarmService.initializeScheduler();
    print('Alarm scheduler service initialized successfully');
  } catch (e) {
    print('Warning: Could not initialize alarm scheduler: $e');
  }
  
  // Initialize native alarm service
  try {
    print('Initializing native alarm service...');
    final nativeAlarmService = NativeAlarmService();
    await nativeAlarmService.initialize();
    print('Native alarm service initialized successfully');
    
    // Set up method channel to listen for native alarm intents
    const methodChannel = MethodChannel('com.example.vibealarm/native_alarm');
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'alarmTriggered') {
        final alarmData = call.arguments as Map<String, dynamic>;
        print('=== ALARM TRIGGERED FROM NATIVE ===');
        print('Alarm Data: $alarmData');
        
        // Create alarm object from native data
        final alarm = Alarm(
          id: alarmData['alarm_id'] ?? 'native_alarm',
          time: alarmData['alarm_time'] ?? 'Unknown',
          period: 'AM', // Default period
          message: alarmData['alarm_message'] ?? 'Time to wake up!',
          frequency: 'Once',
          audio: '',
          audioName: 'Default',
          isActive: true,
          createdAt: DateTime.now(),
        );
        
        // Show the alarm ringing screen
        _showAlarmRingingScreenFromMain(alarm);
      }
    });
    
  } catch (e) {
    print('Warning: Could not initialize native alarm service: $e');
  }
  
  // Initialize audio player service
  final audioPlayer = AudioPlayerService();
  await audioPlayer.initialize();
  
  // Set up alarm callback using the same service instance
  final schedulerService = AlarmService.getSchedulerService();
  if (schedulerService != null) {
    schedulerService.onAlarmTriggered = (alarm) {
      print('=== ALARM TRIGGERED CALLBACK IN MAIN ===');
      print('Alarm ID: ${alarm.id}');
      print('Alarm Time: ${alarm.time}');
      print('Alarm Message: ${alarm.message}');
      
      // Show the alarm ringing screen on top of everything
      _showAlarmRingingScreenFromMain(alarm);
    };
    print('Alarm callback set up successfully');
  } else {
    print('WARNING: Could not get scheduler service instance');
  }
  
  // Check if we need to restore alarms after boot
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkForBootRestore();
  });
  
  runApp(const VibeAlarmApp());
}

class VibeAlarmApp extends StatefulWidget {
  const VibeAlarmApp({super.key});

  @override
  State<VibeAlarmApp> createState() => _VibeAlarmAppState();
}

class _VibeAlarmAppState extends State<VibeAlarmApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check for alarm intent when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAlarmIntent();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _checkForAlarmIntent() {
    // Check if app was launched from alarm notification
    print('Checking for alarm intent...');
    
    // Check for pending alarm data from native side
    _checkNativeAlarmData();
  }
  
  void _checkNativeAlarmData() async {
    try {
      const methodChannel = MethodChannel('com.example.vibealarm/native_alarm');
      final pendingAlarm = await methodChannel.invokeMethod('checkPendingAlarm');
      
      if (pendingAlarm != null) {
        print('=== PENDING ALARM DATA FOUND ===');
        print('Pending Alarm: $pendingAlarm');
        
        // Create alarm object from native data
        final alarm = Alarm(
          id: pendingAlarm['alarm_id'] ?? 'native_alarm',
          time: pendingAlarm['alarm_time'] ?? 'Unknown',
          period: 'AM', // Default period
          message: pendingAlarm['alarm_message'] ?? 'Time to wake up!',
          frequency: 'Once',
          audio: '',
          audioName: 'Default',
          isActive: true,
          createdAt: DateTime.now(),
        );
        
        // Show the alarm ringing screen
        _showAlarmRingingScreenFromMain(alarm);
      }
    } catch (e) {
      print('Error checking native alarm data: $e');
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Check for alarm intent when app resumes
      _checkForAlarmIntent();
    }
  }
  
  void _showAlarmRingingScreen(Alarm alarm) {
    // Show the alarm ringing screen on top of everything
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(
          alarm: alarm,
          onAlarmStopped: () {
            // Stop the alarm audio
            final schedulerService = AlarmService.getSchedulerService();
            if (schedulerService != null) {
              schedulerService.stopAlarmAudio(alarm.id);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
              title: 'VibeAlarm',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Assign the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF8FBFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
