import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final _audioRecorder = AudioRecorder();
  String? _recordingPath;

  Future<void> init() async {
    try {
      final micPermission = await Permission.microphone.request();
      debugPrint('Mic permission: $micPermission');

      if (micPermission != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      rethrow;
    }
  }

  Future<void> startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        await init();
      }

      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      debugPrint('Recording to path: $_recordingPath');

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
      debugPrint('Recording started');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        debugPrint('Stopping recording');
        await _audioRecorder.stop();
        debugPrint('Recording stopped, saved to: $_recordingPath');
        return _recordingPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _audioRecorder.dispose();
      debugPrint('Recorder disposed');
    } catch (e) {
      debugPrint('Error disposing recorder: $e');
      rethrow;
    }
  }

  Future<bool> get isRecording => _audioRecorder.isRecording();
}
