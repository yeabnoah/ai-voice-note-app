import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
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
          const SizedBox(height: 8),
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
    super.dispose();
  }
}
