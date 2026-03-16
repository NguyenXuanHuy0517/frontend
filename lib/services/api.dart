// lib/services/api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart' as m;

const API_BASE_URL = 'http://localhost:8081';

/// Helper: giải nén data từ ApiResponse wrapper { success, message, data }
/// Backend trả về { "success": true, "message": "...", "data": ... }
/// Nếu response là plain List/Object (không bọc wrapper), dùng thẳng.
dynamic _unwrap(dynamic decoded) {
  if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
    return decoded['data'];
  }
  return decoded;
}

class ApiClient {
  // ─── Fetch rooms overview ──────────────────────────────────────────────────
  static Future<List<m.RoomModel>> fetchRoomsOverview() async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/overview');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Lỗi tải danh sách phòng: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final dynamic decoded = json.decode(resp.body);
    final dynamic data = _unwrap(decoded);
    if (data is! List) {
      throw Exception('Dữ liệu phòng không đúng định dạng (nhận: ${data.runtimeType})');
    }
    return data.map((e) => m.RoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Fetch room detail by id ───────────────────────────────────────────────
  static Future<m.RoomModel> fetchRoomDetail(int id) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Lỗi tải chi tiết phòng: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final dynamic decoded = json.decode(resp.body);
    final dynamic data = _unwrap(decoded);
    if (data is! Map<String, dynamic>) {
      throw Exception('Dữ liệu phòng không đúng định dạng');
    }
    return m.RoomModel.fromJson(data);
  }

  // ─── Update full room info (PUT) ───────────────────────────────────────────
  static Future<m.RoomModel> updateRoom(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 10));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Lỗi cập nhật phòng: ${resp.statusCode} ${resp.reasonPhrase}');
    }
    final dynamic decoded = json.decode(resp.body);
    final dynamic data = _unwrap(decoded);
    return m.RoomModel.fromJson(data as Map<String, dynamic>);
  }

  // ─── Update room status (PATCH) ────────────────────────────────────────────
  static Future<void> updateRoomStatus(int id, String status) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/$id/status?status=$status');
    final resp = await http.patch(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Lỗi cập nhật trạng thái: ${resp.statusCode} ${resp.reasonPhrase}');
    }
  }

  // ─── Fetch room by roomCode ────────────────────────────────────────────────
  static Future<m.RoomModel> fetchRoomByCode(String roomCode) async {
    final uri = Uri.parse('$API_BASE_URL/api/business/rooms/code/$roomCode');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw Exception('Không tìm thấy phòng với mã $roomCode');
    }
    final dynamic decoded = json.decode(resp.body);
    final dynamic data = _unwrap(decoded);
    return m.RoomModel.fromJson(data as Map<String, dynamic>);
  }
}