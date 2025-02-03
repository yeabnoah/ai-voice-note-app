import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  double _confidence = 0.0;
  String _currentLocaleId = '';
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      var hasSpeech = await _speech.initialize(
        onError: (error) => debugPrint('Error: $error'),
        onStatus: (status) => debugPrint('Status: $status'),
      );

      if (hasSpeech) {
        var systemLocale = await _speech.systemLocale();
        setState(() {
          _currentLocaleId = systemLocale?.localeId ?? '';
        });
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_speech.isAvailable) {
        await _initSpeech();
      }

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        localeId: _currentLocaleId,
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevel = level;
          });
        },
      );

      setState(() {
        _isListening = true;
        String currentText = _textController.text;
        int lastNewLine = currentText.lastIndexOf('\n');
        if (lastNewLine == -1) {
          _textController.clear();
        } else {
          _textController.text = currentText.substring(0, lastNewLine + 1);
        }
      });
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      if (result.finalResult) {
        _confidence = result.confidence;
      }

      String currentText = _textController.text;
      int lastNewLine = currentText.lastIndexOf('\n');
      if (lastNewLine == -1) {
        _textController.text = result.recognizedWords;
      } else {
        _textController.text =
            currentText.substring(0, lastNewLine + 1) + result.recognizedWords;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Navigator.pop(context, _textController.text);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Your speech will appear here...',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMicButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 40,
              color: _isListening
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
            if (_isListening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 60 + (_soundLevel * 5),
                width: 60 + (_soundLevel * 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }
}
