import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
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

      if (note.content is Map<String, dynamic>) {
        final content = note.content;
        if (!content.toString().endsWith('\n')) {
          content['insert'] = content['insert'] + '\n';
        }
        _controller = quill.QuillController(
          document: quill.Document.fromJson(content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else if (note.content is String) {
        _controller = quill.QuillController(
          document: quill.Document.fromJson([
            {"insert": "${note.content.toString()}\n"}
          ]),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note?.title ?? '',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            if (_note?.tags.isNotEmpty ?? false)
              Text(
                _note!.tags.first,
                style: GoogleFonts.inter(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/editor',
                arguments: _note,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'Delete Note',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure?',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && _note != null) {
                try {
                  await ApiService.deleteNote(_note!.id);
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: quill.QuillEditor.basic(
          configurations: quill.QuillEditorConfigurations(
            controller: _controller,
            // readOnly: true,
            autoFocus: false,
            padding: const EdgeInsets.all(8),
            customStyles: quill.DefaultStyles(
              paragraph: quill.DefaultTextBlockStyle(
                TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                quill.VerticalSpacing(0, 0),
                quill.VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
