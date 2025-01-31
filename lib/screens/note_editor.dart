import 'package:flutter/material.dart';
import 'package:hope/models/note.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class NoteEditor extends StatefulWidget {
  final Note? note;

  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  String? selectedTag;
  Color? selectedTagColor;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _tempWords = '';

  final List<Map<String, dynamic>> availableTags = [
    {'name': 'Personal', 'color': Colors.blue},
    {'name': 'Work', 'color': Colors.green},
    {'name': 'Ideas', 'color': Colors.orange},
    {'name': 'Tasks', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    selectedTag = widget.note?.tag;
    selectedTagColor = widget.note?.tagColor;
    _initSpeech();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      },
    );
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _tempWords = result.recognizedWords;
              if (result.finalResult) {
                final currentContent = _contentController.text;
                final newContent = currentContent.isEmpty
                    ? _tempWords
                    : '$currentContent\n$_tempWords';
                _contentController.text = newContent;
                _tempWords = '';
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  // Tags Row
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableTags.length,
                      itemBuilder: (context, index) {
                        final tag = availableTags[index];
                        final isSelected = selectedTag == tag['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(tag['name']),
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : tag['color'],
                              fontSize: 12,
                            ),
                            backgroundColor: tag['color'].withOpacity(0.1),
                            selectedColor: tag['color'],
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedTag = tag['name'];
                                  selectedTagColor = tag['color'];
                                } else {
                                  selectedTag = null;
                                  selectedTagColor = null;
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add temporary transcription display
                  if (_tempWords.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _tempWords,
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),

                  // Content Field
                  TextFormField(
                    controller: _contentController,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start typing...',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 16,
                        height: 1.8,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some content';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // Bottom Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolbarButton(Icons.format_bold, 'Bold'),
                    _buildToolbarButton(Icons.format_italic, 'Italic'),
                    _buildToolbarButton(Icons.format_list_bulleted, 'List'),
                    _buildToolbarButton(Icons.attach_file, 'Attach'),
                    _buildToolbarButton(Icons.image_outlined, 'Image'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice input button
          FloatingActionButton(
            onPressed: _startListening,
            backgroundColor:
                _isListening ? Colors.red : const Color(0xFF6B4EFF),
            heroTag: 'voice',
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Existing save button
          FloatingActionButton(
            onPressed: _saveNote,
            backgroundColor: const Color(0xFF6B4EFF),
            heroTag: 'save',
            child: const Icon(Icons.save, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: () {
        // Implement formatting functionality
      },
      color: Colors.grey[600],
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('Share', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text('Delete', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                // Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final note = Note(
        id: widget.note?.id ?? const Uuid().v4(),
        title: _titleController.text,
        content: _contentController.text,
        dateCreated: widget.note?.dateCreated ?? now,
        dateModified: now,
        tag: selectedTag,
        tagColor: selectedTagColor,
      );
      Navigator.pop(context, note);
    }
  }
}
