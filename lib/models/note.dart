import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class Note {
  String id;
  String title;
  dynamic content; // This will store the Quill Delta
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

  // Convert Quill Delta to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
      'tag': tag,
    };
  }

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'],
      title: json['title'],
      content: json['content'],
      dateCreated: DateTime.parse(json['createdAt']),
      dateModified: DateTime.parse(json['updatedAt']),
      tag: json['tags']?.isNotEmpty == true ? json['tags'][0] : null,
    );
  }
}
