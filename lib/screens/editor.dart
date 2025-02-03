import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/flutter_quill.dart' show ChangeSource;
import 'package:hope/models/note.dart';
import 'package:hope/screens/speech_to_text_screen.dart';
import 'package:hope/services/api_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart'
    show SpeechRecognitionResult;
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final TextEditingController _themeController = TextEditingController();
  bool _isTransforming = false;
  bool _markdownMode = false;
  final TextEditingController _markdownController = TextEditingController();

  final List<String> _availableTags = [
    'Personal',
    'Work',
    'Ideas',
    'Important'
  ];

  final List<String> _availableThemes = [
    'Persuasive',
    'Professional',
    'Academic',
    'Story Telling',
    'Casual',
    'Funny',
    'Poetic',
    'Technical',
    'Journalistic',
    'Diplomatic',
    'Inspirational',
    'Philosophical',
    'Minimalist',
    'Conversational',
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

  Future<void> _transformWithAI() async {
    if (_themeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an AI style')),
      );
      return;
    }

    setState(() => _isTransforming = true);
    try {
      final content = _controller.document.toPlainText();
      final response =
          await ApiService.transformText(content, _themeController.text);

      _controller.document = quill.Document.fromJson([
        {"insert": "${response['rewritten']}\n"}
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isTransforming = false);
    }
  }

  String _quillToMarkdown() {
    final doc = _controller.document;
    final plainText = doc.toPlainText();
    // Basic conversion - you can enhance this for more formatting
    return plainText;
  }

  void _markdownToQuill(String markdown) {
    _controller.document = quill.Document.fromJson([
      {"insert": markdown}
    ]);
  }

  void _toggleEditMode() {
    setState(() {
      if (_markdownMode) {
        // Convert markdown to quill
        _markdownToQuill(_markdownController.text);
      } else {
        // Convert quill to markdown
        _markdownController.text = _quillToMarkdown();
      }
      _markdownMode = !_markdownMode;
    });
  }

  Widget _buildQuillToolbar() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
            minHeight: 45,
          ),
          child: quill.QuillSimpleToolbar(
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
              showIndent: true,
              showLink: true,
              multiRowsDisplay: false,
              showDividers: true,
              // backgroundColor: Theme.of(context).colorScheme.surface,
              // iconTheme: quill.QuillIconTheme(
              //   iconSelectedColor: Theme.of(context).colorScheme.primary,
              //   iconUnselectedColor: Theme.of(context).colorScheme.onSurface,
              // ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _existingNote != null ? 'Edit Note' : 'New Note',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          if (_isTransforming || _isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(
                _markdownMode ? Icons.code_off : Icons.code,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _toggleEditMode,
              tooltip: 'Toggle Markdown Mode',
            ),
            IconButton(
              icon: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: _transformWithAI,
              tooltip: 'Transform with AI',
            ),
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveNote,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                // Tag and Theme fields in a row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedTag,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select tag',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _themeController.text.isEmpty
                              ? null
                              : _themeController.text,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select AI style',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixIcon: Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          items: _availableThemes.map((theme) {
                            return DropdownMenuItem(
                              value: theme,
                              child: Text(theme),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _themeController.text = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                child: Column(
                  children: [
                    if (!_markdownMode) _buildQuillToolbar(),
                    Expanded(
                      child: _markdownMode
                          ? TextField(
                              controller: _markdownController,
                              maxLines: null,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write in Markdown...',
                                contentPadding: const EdgeInsets.all(16),
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .hintColor
                                      .withOpacity(0.6),
                                ),
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                filled: true,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: quill.QuillEditor.basic(
                                configurations: quill.QuillEditorConfigurations(
                                  controller: _controller,
                                  autoFocus: false,
                                  expands: false,
                                  padding: const EdgeInsets.all(16),
                                  placeholder: 'Start writing...',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        elevation: 2,
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
    _themeController.dispose();
    _markdownController.dispose();
    super.dispose();
  }
}
