import 'package:flutter/material.dart';

class Note {
  String id;
  String title;
  dynamic content; // Changed to dynamic to store rich text data
  DateTime dateCreated;
  DateTime dateModified;
  String? tag;
  Color? tagColor;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.tag,
    this.tagColor,
  });
}
