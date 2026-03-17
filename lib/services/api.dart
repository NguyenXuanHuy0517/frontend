// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart' as m;

const _base = 'http://localhost:8081';

/// Unwrap ApiResponse wrapper { "success":true, "data": ... }
/// Nếu response là plain data (không có key "data") thì trả thẳng
dynamic _unwrap(dynamic decoded) {
  if (decoded is Map<String, dynamic>) {
    if (decoded.containsKey('data')) return decoded['data'];
    if (decoded.containsKey('success') && decoded['success'] == false) {
      throw Exception(decoded['message'] ?? 'Lỗi từ server');
    }
  }
  return decoded;
}

class ApiClient {
  // ── Fetch rooms overview ───────────────────────────────────────────────────
  static Future<List<m.RoomModel>> fetchRoomsOverview() async {
    final resp = await http.get(Uri.parse('$_base/api/business/rooms/overview'))
        .timeout(const Duration(seconds: 15));
    _checkStatus(resp);
    final data = _unwrap(json.decode(resp.body));
    if (data is! List) throw Exception('Dữ liệu không đúng định dạng (không phải List)');
    return data.map((e) => m.RoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Fetch room detail ──────────────────────────────────────────────────────
  static Future<m.RoomModel> fetchRoomDetail(int id) async {
    final resp = await http.get(Uri.parse('$_base/api/business/rooms/$id'))
        .timeout(const Duration(seconds: 10));
    _checkStatus(resp);
    final data = _unwrap(json.decode(resp.body));
    return m.RoomModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Update room (PUT) ──────────────────────────────────────────────────────
  // Backend nhận RoomDetailDTO với BigDecimal fields.
  // Gửi số nguyên hoặc double đều được (Jackson tự convert).
  static Future<m.RoomModel> updateRoom(int id, Map<String, dynamic> payload) async {
    final resp = await http.put(
      Uri.parse('$_base/api/business/rooms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 10));
    _checkStatus(resp);
    final data = _unwrap(json.decode(resp.body));
    return m.RoomModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Update room status (PATCH) ─────────────────────────────────────────────
  // Backend: PATCH /api/business/rooms/{id}/status?status=AVAILABLE
  // Trả về ApiResponse<Void> (data = null) → chỉ cần kiểm tra success
  static Future<void> updateRoomStatus(int id, String status) async {
    final resp = await http.patch(
      Uri.parse('$_base/api/business/rooms/$id/status?status=$status'),
    ).timeout(const Duration(seconds: 10));
    _checkStatus(resp);
    // Không cần parse data, chỉ cần không throw
  }

  // ── Fetch room by code ─────────────────────────────────────────────────────
  static Future<m.RoomModel> fetchRoomByCode(String roomCode) async {
    final resp = await http.get(Uri.parse('$_base/api/business/rooms/code/$roomCode'))
        .timeout(const Duration(seconds: 10));
    _checkStatus(resp);
    final data = _unwrap(json.decode(resp.body));
    return m.RoomModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Helper: check HTTP status and throw readable error ────────────────────
  static void _checkStatus(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;

    // Try to extract backend error message from ApiResponse body
    try {
      final body = json.decode(resp.body);
      final msg = body['message'] ?? body['error'] ?? resp.reasonPhrase;
      throw Exception('Lỗi cập nhật trạng thái: ${resp.statusCode}. $msg');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    }
  }
}