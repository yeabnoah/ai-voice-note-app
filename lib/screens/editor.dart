import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedTag;
  bool _isLoading = false;
  Note? _existingNote;

  final List<String> _availableTags = [
    'Personal',
    'Work',
    'Ideas',
    'Important'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = ModalRoute.of(context)?.settings.arguments as Note?;
    if (note != null && _existingNote == null) {
      _existingNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content.toString();
      _selectedTag = _availableTags.firstWhere(
        (tag) => tag.toLowerCase() == note.tag?.toLowerCase(),
        orElse: () => note.tag ?? '',
      );
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_existingNote != null) {
        await ApiService.updateNote(
          _existingNote!.id,
          _titleController.text,
          _contentController.text,
          _selectedTag != null ? [_selectedTag!] : [],
        );
      } else {
        await ApiService.createNote(
          _titleController.text,
          _contentController.text,
          _selectedTag != null ? [_selectedTag!] : [],
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingNote != null ? 'Edit Note' : 'New Note',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (_existingNote != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.deleteNote(_existingNote!.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                border: const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedTag,
              hint: Text(
                'Select Tag',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              items: _availableTags
                  .map((tag) => DropdownMenuItem(
                        value: tag,
                        child: Text(tag),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedTag = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: GoogleFonts.inter(color: Colors.white),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Start typing...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _saveNote,
        backgroundColor: Colors.white,
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Icon(Icons.save, color: Colors.black),
      ),
    );
  }
}
