// lib/services/api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart' as m;

const API_BASE_URL = 'http://localhost:8081';

class ApiClient {
  // Fetch rooms overview
  static Future<List<m.RoomModel>> fetchRoomsOverview() async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/overview');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load rooms overview: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final List data = json.decode(resp.body);
    return data.map((e) => m.RoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Fetch room detail by id
  static Future<m.RoomModel> fetchRoomDetail(int id) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load room detail: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final Map<String, dynamic> data = json.decode(resp.body);
    return m.RoomModel.fromJson(data);
  }

  // Update full room info (PUT)
  static Future<m.RoomModel> updateRoom(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to update room: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final Map<String, dynamic> data = json.decode(resp.body);
    return m.RoomModel.fromJson(data);
  }

  // Update just the room status (PATCH) using request param ?status=...
  static Future<void> updateRoomStatus(int id, String status) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id/status?status=$status');
    final resp = await http.patch(uri);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to update room status: ${resp.statusCode} ${resp.reasonPhrase}');
    }
  }

  // Fetch room by roomCode
  static Future<m.RoomModel> fetchRoomByCode(String roomCode) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/code/$roomCode');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load room by code: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final Map<String, dynamic> data = json.decode(resp.body);
    return m.RoomModel.fromJson(data);
  }
}
