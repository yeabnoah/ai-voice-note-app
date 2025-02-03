import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: quill.Document()..insert(0, '\n'),
      selection: const TextSelection.collapsed(offset: 0),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
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
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: quill.QuillEditor.basic(
            configurations: quill.QuillEditorConfigurations(
              controller: _controller,
              // readOnly: true,
              autoFocus: false,
              padding: EdgeInsets.zero,
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
    _controller.dispose();
    super.dispose();
  }
}
