import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope/models/note.dart';
import 'package:hope/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final fetchedNotes = await ApiService.getAllNotes();
      setState(() {
        notes = fetchedNotes;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _navigateToEditor([Note? note]) async {
    await Navigator.pushNamed(
      context,
      '/editor',
      arguments: note,
    );
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(
                  child: Text(
                    'No notes yet',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: notes.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        subtitle: Text(
                          note.content.toString(),
                          style: GoogleFonts.inter(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: note.tag != null
                            ? Chip(
                                label: Text(
                                  note.tag!,
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                backgroundColor: note.tagColor,
                              )
                            : null,
                        onTap: () => _navigateToEditor(note),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
