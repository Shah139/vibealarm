import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../models/audio_file.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioFile? _currentAudio;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  AudioFile? get currentAudio => _currentAudio;

  // Streams for UI updates
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Initialize the audio player
  Future<void> initialize() async {
    try {
      // Listen to player state changes
      _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
      });

      // Listen to duration changes
      _player.durationStream.listen((duration) {
        _duration = duration ?? Duration.zero;
      });

      // Listen to position changes
      _player.positionStream.listen((position) {
        _position = position;
      });

      // Listen to errors
      _player.playerStateStream.listen((state) {
        // Handle player state changes
        if (state.processingState.toString().contains('error')) {
          print('Audio player error: ${state.processingState}');
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  /// Load and play audio file
  Future<void> playAudio(AudioFile audioFile) async {
    try {
      // Check if file exists
      final file = File(audioFile.localPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: ${audioFile.localPath}');
      }

      // Stop current playback if any
      await stop();

      // Set current audio
      _currentAudio = audioFile;

      // Set audio source
      await _player.setFilePath(audioFile.localPath);

      // Start playing
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Play audio from local path
  Future<void> playFromPath(String localPath) async {
    try {
      // Check if file exists
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $localPath');
      }

      // Stop current playback if any
      await stop();

      // Set audio source
      await _player.setFilePath(localPath);

      // Start playing
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio from path: $e');
    }
  }

  /// Play audio from URL (for testing or remote audio)
  Future<void> playFromUrl(String url) async {
    try {
      // Stop current playback if any
      await stop();

      // Set audio source
      await _player.setUrl(url);

      // Start playing
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio from URL: $e');
    }
  }

  /// Pause audio playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  /// Resume audio playback
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  /// Stop audio playback and reset
  Future<void> stop() async {
    try {
      await _player.stop();
      _currentAudio = null;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking audio: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      print('Error setting speed: $e');
    }
  }

  /// Loop audio
  Future<void> setLooping(bool loop) async {
    try {
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    } catch (e) {
      print('Error setting loop mode: $e');
    }
  }

  /// Get current volume
  double get volume => _player.volume;

  /// Get current speed
  double get speed => _player.speed;

  /// Get loop mode
  LoopMode get loopMode => _player.loopMode;

  /// Check if audio is loaded
  bool get hasAudio => _player.audioSource != null;

  /// Get audio source info
  String? get audioSourceInfo {
    final source = _player.audioSource;
    if (source != null) {
      return source.toString();
    }
    return null;
  }

  /// Preview audio file (play for a few seconds)
  Future<void> previewAudio(AudioFile audioFile, {Duration previewDuration = const Duration(seconds: 5)}) async {
    try {
      // Load audio
      await _player.setFilePath(audioFile.localPath);
      
      // Start playing
      await _player.play();
      
      // Stop after preview duration
      Future.delayed(previewDuration, () {
        if (_player.playing) {
          _player.pause();
        }
      });
    } catch (e) {
      throw Exception('Failed to preview audio: $e');
    }
  }

  /// Get formatted duration string
  String getFormattedDuration() {
    return _formatDuration(_duration);
  }

  /// Get formatted position string
  String getFormattedPosition() {
    return _formatDuration(_position);
  }

  /// Format duration to MM:SS format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// Check if audio is at the end
  bool get isAtEnd {
    return _position >= _duration && _duration > Duration.zero;
  }

  /// Skip to next track (if playlist support is added later)
  Future<void> next() async {
    // This can be extended for playlist functionality
    await stop();
  }

  /// Skip to previous track (if playlist support is added later)
  Future<void> previous() async {
    // This can be extended for playlist functionality
    await stop();
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }

  /// Reset player state
  void reset() {
    _currentAudio = null;
    _isPlaying = false;
    _duration = Duration.zero;
    _position = Duration.zero;
  }
} 