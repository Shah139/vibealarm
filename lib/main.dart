import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'dart:io'; // Added for Directory.current

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
  
  // Initialize audio player service
  final audioPlayer = AudioPlayerService();
  await audioPlayer.initialize();
  
  runApp(const VibeAlarmApp());
}

class VibeAlarmApp extends StatelessWidget {
  const VibeAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
              title: 'VibeAlarm',
      debugShowCheckedModeBanner: false,
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
