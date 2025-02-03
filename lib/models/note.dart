import 'dart:convert';

class Note {
  final String id;
  final String title;
  final dynamic content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    var content = json['content'];
    // If content is a string (likely JSON string), parse it
    if (content is String) {
      try {
        content = jsonDecode(content);
      } catch (e) {
        // If parsing fails, keep it as string
        content = [
          {"insert": "$content\n"}
        ];
      }
    }

    return Note(
      id: json['_id'],
      title: json['title'],
      content: content,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
