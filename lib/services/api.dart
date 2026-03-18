// lib/services/api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart' as m;

const API_BASE_URL = 'http://localhost:8081';

class ApiClient {
  // ─── Rooms ──────────────────────────────────────────────────────────────────

  /// Lấy danh sách tổng quan tất cả phòng
  static Future<List<m.RoomModel>> fetchRoomsOverview() async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/overview');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Lỗi tải danh sách phòng: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final body = json.decode(resp.body);
    List items;
    if (body is List) {
      items = body;
    } else if (body is Map<String, dynamic>) {
      if (body['data'] is List) {
        items = body['data'];
      } else if (body['rooms'] is List) {
        items = body['rooms'];
      } else {
        throw Exception('Unexpected response format for rooms overview: Map without "data"/"rooms" list keys. Got keys: ${body.keys}');
      }
    } else {
      throw Exception('Unexpected response type: ${body.runtimeType}');
    }
    return items.map((e) => m.RoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy chi tiết phòng theo ID
  static Future<m.RoomModel> fetchRoomDetail(int id) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Lỗi tải chi tiết phòng: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    return m.RoomModel.fromJson(json.decode(resp.body) as Map<String, dynamic>);
  }

  /// Tìm phòng theo mã phòng (roomCode)
  static Future<m.RoomModel> fetchRoomByCode(String roomCode) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/code/$roomCode');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Không tìm thấy phòng với mã $roomCode');
    }
    return m.RoomModel.fromJson(json.decode(resp.body) as Map<String, dynamic>);
  }

  /// THÊM PHÒNG MỚI (POST) - yêu cầu areaId
  static Future<m.RoomModel> createRoom(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (resp.statusCode != 201) {
      // Lấy message lỗi từ backend nếu có
      String errMsg = 'Lỗi thêm phòng: ${resp.statusCode}';
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['message'] != null) errMsg = body['message'];
      } catch (_) {}
      throw Exception(errMsg);
    }
    return m.RoomModel.fromJson(json.decode(resp.body) as Map<String, dynamic>);
  }

  /// Cập nhật thông tin phòng (PUT)
  static Future<m.RoomModel> updateRoom(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String errMsg = 'Lỗi cập nhật phòng: ${resp.statusCode}';
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['message'] != null) errMsg = body['message'];
      } catch (_) {}
      throw Exception(errMsg);
    }
    return m.RoomModel.fromJson(json.decode(resp.body) as Map<String, dynamic>);
  }

  /// Cập nhật trạng thái phòng (PATCH)
  static Future<void> updateRoomStatus(int id, String status) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id/status?status=$status');
    final resp = await http.patch(uri);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Lỗi cập nhật trạng thái: ${resp.statusCode} ${resp.reasonPhrase}');
    }
  }
}