import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show ChangeSource;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';
import 'package:hope/screens/speech_to_text_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart'
    show SpeechRecognitionResult;

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late quill.QuillController _controller;
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  String? _selectedTag;
  bool _isLoading = false;
  bool _showAllTools = false;
  Note? _existingNote;

  final List<String> _availableTags = [
    'Personal',
    'Work',
    'Ideas',
    'Important'
  ];

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentLocaleId = '';
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _initSpeech();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = ModalRoute.of(context)?.settings.arguments as Note?;
    if (note != null && _existingNote == null) {
      _existingNote = note;
      _titleController.text = note.title;
      _selectedTag = note.tags.isNotEmpty ? note.tags.first : null;

      try {
        final content = note.content;
        _controller = quill.QuillController(
          document: content is List
              ? quill.Document.fromJson(content)
              : quill.Document.fromJson([
                  {"insert": "${content.toString()}\n"}
                ]),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        debugPrint('Error loading note content: $e');
      }
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final contentJson = _controller.document.toDelta().toJson();

      if (_existingNote != null) {
        await ApiService.updateNote(
          _existingNote!.id,
          _titleController.text,
          contentJson,
          _selectedTag != null ? [_selectedTag!] : [],
        );
      } else {
        await ApiService.createNote(
          _titleController.text,
          contentJson,
          _selectedTag != null ? [_selectedTag!] : [],
        );
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openSpeechToText() async {
    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const SpeechToTextScreen(),
      ),
    );

    if (text != null && text.isNotEmpty) {
      _controller.document.insert(
        _controller.document.length,
        text,
      );
    }
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
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Future<void> _toggleListening() async {
    try {
      if (!_isListening) {
        if (!_speech.isAvailable) {
          await _initSpeech();
        }

        // Move cursor to end before starting
        _controller.updateSelection(
          TextSelection.collapsed(offset: _controller.document.length),
          ChangeSource.local,
        );

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

        setState(() => _isListening = true);
      } else {
        await _speech.stop();
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error toggling speech recognition: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        // Always append to the end of the document
        final currentText = _controller.document.toPlainText();

        if (result.finalResult) {
          // For final results, append with newline
          _controller.document = quill.Document.fromJson([
            {"insert": currentText + result.recognizedWords + '\n'}
          ]);
        } else {
          // For partial results, update the last line
          final lastNewLine = currentText.lastIndexOf('\n');
          final textBeforeCursor =
              lastNewLine >= 0 ? currentText.substring(0, lastNewLine + 1) : '';

          _controller.document = quill.Document.fromJson([
            {"insert": textBeforeCursor + result.recognizedWords}
          ]);
        }
      });
    }
  }

  Widget _buildQuillToolbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: quill.QuillSimpleToolbar(
                  configurations: quill.QuillSimpleToolbarConfigurations(
                    controller: _controller,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showUndo: true,
                    showRedo: true,
                    // Disable other buttons
                    showStrikeThrough: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showAlignmentButtons: false,
                    showHeaderStyle: false,
                    showListBullets: false,
                    showListNumbers: false,
                    showQuote: false,
                    showCodeBlock: false,
                    showIndent: false,
                    showLink: false,
                    multiRowsDisplay: true,
                    showDividers: true,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showAllTools ? Icons.more_horiz : Icons.more_vert,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => setState(() => _showAllTools = !_showAllTools),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingNote != null ? 'Edit Note' : 'New Note'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveNote,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: DropdownButtonFormField<String>(
              value: _selectedTag,
              decoration: const InputDecoration(
                hintText: 'Select tag',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _availableTags.map((tag) {
                return DropdownMenuItem(
                  value: tag,
                  child: Text(tag),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTag = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _controller,
                  autoFocus: false,
                  expands: false,
                  padding: EdgeInsets.zero,
                  scrollable: true,
                  placeholder: 'Start writing...',
                ),
              ),
            ),
          ),
          _buildQuillToolbar(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
            if (_isListening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 40 + (_soundLevel * 5),
                height: 40 + (_soundLevel * 5),
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
    _titleController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
