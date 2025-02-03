import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';

class NoteReaderScreen extends StatefulWidget {
  const NoteReaderScreen({super.key});

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  late quill.QuillController _controller;
  Note? _note;
  bool _markdownMode = false;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _ttsInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: quill.Document()..insert(0, '\n'),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    try {
      // Initialize with platform check
      if (Platform.isAndroid) {
        await _tts.awaitSpeakCompletion(true);
        await _tts.setQueueMode(1); // 1 for sequential
        var engines = await _tts.getEngines;
        if (engines.isNotEmpty) {
          await _tts.setEngine(engines.first);
        }
      }

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _ttsInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> _speak() async {
    try {
      if (!_ttsInitialized) await _initTts();

      final text = _controller.document.toPlainText();
      if (text.isNotEmpty) {
        setState(() => _isSpeaking = true);
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _isSpeaking = false);
    await _tts.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = ModalRoute.of(context)?.settings.arguments as Note?;
    if (note != null && _note == null) {
      _note = note;

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
        // Fallback for malformed content
        _controller = quill.QuillController(
          document: quill.Document()..insert(0, note.content.toString()),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
  }

  String _quillToMarkdown() {
    final doc = _controller.document;
    return doc.toPlainText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note?.title ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_note?.tags.isNotEmpty ?? false)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _note!.tags.first,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.stop_circle : Icons.play_circle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _isSpeaking ? _stop : _speak,
            tooltip: _isSpeaking ? 'Stop Reading' : 'Read Aloud',
          ),
          IconButton(
            icon: Icon(
              _markdownMode ? Icons.code_off : Icons.code,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => setState(() => _markdownMode = !_markdownMode),
            tooltip: 'Toggle Markdown View',
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/editor',
                arguments: _note,
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _markdownMode
              ? Markdown(
                  data: _quillToMarkdown(),
                  selectable: true,
                  padding: const EdgeInsets.all(16),
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyLarge,
                    h1: Theme.of(context).textTheme.headlineMedium,
                    h2: Theme.of(context).textTheme.headlineSmall,
                    h3: Theme.of(context).textTheme.titleLarge,
                    h4: Theme.of(context).textTheme.titleMedium,
                    h5: Theme.of(context).textTheme.titleSmall,
                    h6: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                )
              : Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: quill.QuillEditor.basic(
                    configurations: quill.QuillEditorConfigurations(
                      controller: _controller,
                      // readOnly: true,
                      autoFocus: false,
                      padding: const EdgeInsets.all(16),
                      scrollable: true,
                      // customStyles: quill.DefaultStyles(
                      //   paragraph: quill.DefaultTextBlockStyle(
                      //     Theme.of(context).textTheme.bodyLarge!,
                      //     const VerticalSpacing(0, 0),
                      //     const VerticalSpacing(0, 0),
                      //     null,
                      //   ),
                      // ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Note',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
              ),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && _note != null) {
      try {
        await ApiService.deleteNote(_note!.id);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }
}
