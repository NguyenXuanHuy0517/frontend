// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart' as m;

const _base = 'http://localhost:8081';
const _currentHostId = 1; // Thực tế lấy từ JWT token sau khi login

class ApiClient {
  // ── Token storage ──────────────────────────────────────────────────────────
  // Lưu JWT token sau khi login thành công
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;
  static bool get hasToken => _token != null;

  // ── Headers ────────────────────────────────────────────────────────────────
  // Header JSON thuần (cho các endpoint không cần auth)
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // Header có kèm Authorization Bearer token
  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Header GET có auth (không có Content-Type)
  static Map<String, String> get _getAuthHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Rooms ──────────────────────────────────────────────────────────────────

  static Future<List<m.RoomModel>> fetchRoomsOverview() async {
    final r = await http.get(
      Uri.parse('$_base/api/business/rooms/overview'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi tải danh sách phòng');
    // FIX: backend có thể trả List hoặc Map wrapper { "data": [...] }
    final decoded = json.decode(r.body);
    final List rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map) {
      // Thử các key phổ biến: data, rooms, content
      rawList = (decoded['data'] ?? decoded['rooms'] ?? decoded['content'] ?? []) as List;
    } else {
      rawList = [];
    }
    return rawList
        .map((e) => m.RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<m.RoomModel> fetchRoomDetail(int id) async {
    final r = await http.get(
      Uri.parse('$_base/api/business/rooms/$id'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi tải chi tiết phòng');
    return m.RoomModel.fromJson(json.decode(r.body));
  }

  static Future<m.RoomModel> fetchRoomByCode(String code) async {
    final r = await http.get(
      Uri.parse('$_base/api/business/rooms/code/$code'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Không tìm thấy phòng mã $code');
    return m.RoomModel.fromJson(json.decode(r.body));
  }

  static Future<m.RoomModel> createRoom(Map<String, dynamic> payload) async {
    final r = await http.post(
      Uri.parse('$_base/api/business/rooms'),
      headers: _authHeaders,
      body: json.encode(payload),
    );
    _check(r, 'Lỗi thêm phòng');
    return m.RoomModel.fromJson(json.decode(r.body));
  }

  static Future<m.RoomModel> updateRoom(int id, Map<String, dynamic> payload) async {
    final r = await http.put(
      Uri.parse('$_base/api/business/rooms/$id'),
      headers: _authHeaders,
      body: json.encode(payload),
    );
    _check(r, 'Lỗi cập nhật phòng');
    return m.RoomModel.fromJson(json.decode(r.body));
  }

  static Future<void> updateRoomStatus(int id, String status) async {
    final r = await http.patch(
      Uri.parse('$_base/api/business/rooms/$id/status?status=$status'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi cập nhật trạng thái phòng');
  }

  // ── Tenants ────────────────────────────────────────────────────────────────

  static Future<List<m.TenantModel>> fetchTenants({int? hostId}) async {
    final id = hostId ?? _currentHostId;
    final r = await http.get(
      Uri.parse('$_base/api/business/tenants/by-host/$id'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi tải danh sách người thuê');
    return (json.decode(r.body) as List)
        .map((e) => m.TenantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<m.TenantModel> fetchTenantDetail(int tenantId) async {
    final r = await http.get(
      Uri.parse('$_base/api/business/tenants/$tenantId'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi tải thông tin người thuê');
    return m.TenantModel.fromJson(json.decode(r.body));
  }

  static Future<m.TenantModel> createTenant(Map<String, dynamic> payload) async {
    final r = await http.post(
      Uri.parse('$_base/api/business/tenants'),
      headers: _authHeaders,
      body: json.encode(payload),
    );
    _check(r, 'Lỗi tạo người thuê mới');
    return m.TenantModel.fromJson(json.decode(r.body));
  }

  static Future<m.TenantModel> updateTenant(int id, Map<String, dynamic> payload) async {
    final r = await http.put(
      Uri.parse('$_base/api/business/tenants/$id'),
      headers: _authHeaders,
      body: json.encode(payload),
    );
    _check(r, 'Lỗi cập nhật người thuê');
    return m.TenantModel.fromJson(json.decode(r.body));
  }

  static Future<m.TenantModel> toggleTenantActive(int id) async {
    final r = await http.patch(
      Uri.parse('$_base/api/business/tenants/$id/toggle-active'),
      headers: _getAuthHeaders,
    );
    _check(r, 'Lỗi thay đổi trạng thái tài khoản');
    return m.TenantModel.fromJson(json.decode(r.body));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static void _check(http.Response r, String msg) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      String detail = '';
      try {
        final body = json.decode(r.body);
        if (body is Map && body['message'] != null) {
          detail = ': ${body['message']}';
        }
      } catch (_) {}
      throw Exception('$msg (${r.statusCode})$detail');
    }
  }
}