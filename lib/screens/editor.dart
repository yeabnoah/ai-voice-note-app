import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';
import 'package:hope/services/speech_service.dart';
import 'package:hope/services/voice_service.dart';

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
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;
  String? _recordingPath;

  final List<String> _availableTags = [
    'Personal',
    'Work',
    'Ideas',
    'Important'
  ];

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _checkSpeechAvailability();
    _voiceService.init();
  }

  Future<void> _checkSpeechAvailability() async {
    final available = await _speechService.init();
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Speech recognition is not available on this device. You can still type your notes.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
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

  Future<void> _toggleListening() async {
    try {
      if (!_isListening) {
        await _speechService.startListening((text) {
          _controller.document.insert(
            _controller.document.length,
            '$text ',
          );
        });
        setState(() => _isListening = true);
      } else {
        await _speechService.stopListening();
        setState(() => _isListening = false);
      }
    } catch (e) {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech recognition error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
                child: _showAllTools
                    ? quill.QuillSimpleToolbar(
                        configurations: quill.QuillSimpleToolbarConfigurations(
                          controller: _controller,
                          showBoldButton: true,
                          showItalicButton: true,
                          showUnderLineButton: true,
                          showStrikeThrough: true,
                          showColorButton: true,
                          showBackgroundColorButton: true,
                          showClearFormat: true,
                          showAlignmentButtons: true,
                          showHeaderStyle: true,
                          showListBullets: true,
                          showListNumbers: true,
                          showQuote: true,
                          showCodeBlock: true,
                          showIndent: true,
                          showLink: true,
                          multiRowsDisplay: true,
                          showDividers: true,
                        ),
                      )
                    : quill.QuillSimpleToolbar(
                        configurations: quill.QuillSimpleToolbarConfigurations(
                          controller: _controller,
                          showBoldButton: true,
                          showItalicButton: true,
                          showUnderLineButton: true,
                          showListBullets: true,
                          showColorButton: true,
                          showBackgroundColorButton: false,
                          showClearFormat: false,
                          showHeaderStyle: false,
                          showListNumbers: false,
                          showQuote: false,
                          showCodeBlock: false,
                          showIndent: false,
                          showLink: false,
                          showStrikeThrough: false,
                          showAlignmentButtons: false,
                          multiRowsDisplay: false,
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

  Widget _buildVoiceNotesList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _recordingPath != null ? 1 : 0,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.audio_file),
            title: Text('Recording'),
            onTap: () {
              _controller.document.insert(
                _controller.document.length - 1,
                '[Voice Note] ',
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_isRecording) {
        await _voiceService.startRecording();
        setState(() {
          _isRecording = true;
        });
      } else {
        final path = await _voiceService.stopRecording();
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });

        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording saved successfully')),
          );
          // Insert the recording reference into the editor
          _controller.document.insert(
            _controller.document.length,
            '[Voice Recording: ${path.split('/').last}]\n',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).primaryColor,
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          size: 32,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedTag,
              decoration: const InputDecoration(
                hintText: 'Select tag',
                border: OutlineInputBorder(),
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
          if (_recordingPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Recording saved: $_recordingPath'),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _speechService.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}
