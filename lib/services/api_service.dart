import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hope/models/note.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // For iOS simulator

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    }
    throw Exception(json.decode(response.body)['message']);
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    }
    throw Exception(json.decode(response.body)['message']);
  }

  static Future<List<Note>> getAllNotes() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/note/getallnotes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => Note(
                id: json['_id'],
                title: json['title'],
                content: json['content'],
                dateCreated: DateTime.parse(json['createdAt']),
                dateModified: DateTime.parse(json['updatedAt']),
                tag: json['tags']?.isNotEmpty == true ? json['tags'][0] : null,
              ))
          .toList();
    }
    throw Exception('Failed to load notes');
  }

  static Future<Note> createNote(
      String title, dynamic content, List<String> tags) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/note/createNote'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'content': json.encode(content),
        'tags': tags,
      }),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return Note(
        id: json['_id'],
        title: json['title'],
        content: json['content'],
        dateCreated: DateTime.parse(json['createdAt']),
        dateModified: DateTime.parse(json['updatedAt']),
        tag: json['tags']?.isNotEmpty == true ? json['tags'][0] : null,
      );
    }
    throw Exception('Failed to create note');
  }

  static Future<Note> updateNote(
      String id, String title, dynamic content, List<String> tags) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/note/singlenote/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'content': json.encode(content),
        'tags': tags,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Note(
        id: json['_id'],
        title: json['title'],
        content: json['content'],
        dateCreated: DateTime.parse(json['createdAt']),
        dateModified: DateTime.parse(json['updatedAt']),
        tag: json['tags']?.isNotEmpty == true ? json['tags'][0] : null,
      );
    }
    throw Exception('Failed to update note');
  }

  static Future<void> deleteNote(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/note/singlenote/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete note');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse(
            '$baseUrl/note/getallnotes'), // Using an authenticated endpoint to validate
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    return await validateToken();
  }
}
