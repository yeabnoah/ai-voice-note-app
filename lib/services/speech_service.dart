import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _speechEnabled = false;

  Future<bool> init() async {
    if (_speechEnabled) return true;

    try {
      debugPrint('Initializing speech recognition...');

      // Request permission and initialize
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done') {
            _speech.stop();
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech recognition error: $errorNotification');
        },
        debugLogging: true,
      );

      debugPrint('Speech recognition initialized: $_speechEnabled');

      if (!_speechEnabled) {
        debugPrint('Failed to initialize speech recognition');
        return false;
      }

      // Check available locales
      final locales = await _speech.locales();
      debugPrint(
          'Available locales: ${locales.map((e) => e.localeId).join(', ')}');

      return true;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _speechEnabled = false;
      return false;
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_speechEnabled) {
      final initialized = await init();
      if (!initialized) {
        throw Exception('Speech recognition not available');
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          debugPrint('Speech result: ${result.recognizedWords}');
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenMode: ListenMode.dictation,
        partialResults: false,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  Future<void> dispose() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
