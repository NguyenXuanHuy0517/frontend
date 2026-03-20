// lib/models/models.dart

// ─── Enums ────────────────────────────────────────────────────────────────────

enum RoomStatus { available, occupied, maintenance, rented, deposited }

enum InvoiceStatus { paid, pending, overdue }

enum ContractStatus { active, expired, terminated }

// ─── Helpers: parse số an toàn từ JSON (BigDecimal/Float/int/String) ──────────

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
  return fallback;
}

double _parseDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
  return null;
}

ContractStatus? _parseContractStatus(dynamic val) {
  switch ((val ?? '').toString().toUpperCase()) {
    case 'ACTIVE':     return ContractStatus.active;
    case 'EXPIRED':    return ContractStatus.expired;
    case 'TERMINATED': return ContractStatus.terminated;
    default:           return null;
  }
}

// ─── RoomModel ────────────────────────────────────────────────────────────────

class RoomModel {
  final int roomId;
  final String roomCode;
  final int basePrice;
  final int elecPrice;
  final int waterPrice;
  final RoomStatus status;
  final int areaSize;
  final List<String> images;
  final List<String> amenities;
  final String areaName;
  final String address;
  final double latitude;
  final double longitude;
  final int areaId;

  // Legacy fields for UI compatibility
  final String id;
  final String area;
  final String? tenant;
  final int rent;
  final int floor;

  RoomModel({
    required this.roomId,
    required this.roomCode,
    required this.basePrice,
    required this.elecPrice,
    required this.waterPrice,
    required this.status,
    required this.areaSize,
    required this.images,
    required this.amenities,
    required this.areaName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.areaId = 0,
    required this.id,
    required this.area,
    this.tenant,
    required this.rent,
    required this.floor,
  });

  /// Status dạng String khớp với backend
  String get statusString => switch (status) {
    RoomStatus.available   => 'AVAILABLE',
    RoomStatus.occupied    => 'OCCUPIED',
    RoomStatus.maintenance => 'MAINTENANCE',
    RoomStatus.rented      => 'RENTED',
    RoomStatus.deposited   => 'DEPOSITED',
  };

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    RoomStatus parseStatus(dynamic s) {
      switch ((s ?? 'AVAILABLE').toString().toUpperCase()) {
        case 'AVAILABLE':   return RoomStatus.available;
        case 'OCCUPIED':    return RoomStatus.occupied;
        case 'MAINTENANCE': return RoomStatus.maintenance;
        case 'RENTED':      return RoomStatus.rented;
        case 'DEPOSITED':   return RoomStatus.deposited;
        default:            return RoomStatus.available;
      }
    }

    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final roomCode = json['roomCode']?.toString() ?? '';
    final roomId   = _parseInt(json['roomId']);

    return RoomModel(
      roomId:     roomId,
      roomCode:   roomCode,
      basePrice:  _parseInt(json['basePrice']),
      elecPrice:  _parseInt(json['elecPrice']),
      waterPrice: _parseInt(json['waterPrice']),
      status:     parseStatus(json['status']),
      areaSize:   _parseInt(json['areaSize']),
      images:     parseStringList(json['images']),
      amenities:  parseStringList(json['amenities']),
      areaName:   json['areaName']?.toString() ?? '',
      address:    json['address']?.toString() ?? '',
      latitude:   _parseDouble(json['latitude']),
      longitude:  _parseDouble(json['longitude']),
      areaId:     _parseInt(json['areaId']),
      id:         roomCode.isNotEmpty ? roomCode : 'R$roomId',
      area:       json['areaName']?.toString() ?? '',
      tenant:     json['tenantName']?.toString(),
      rent:       _parseInt(json['basePrice']),
      floor:      _parseInt(json['floor'], 1),
    );
  }

  RoomModel copyWith({
    int? roomId, String? roomCode,
    int? basePrice, int? elecPrice, int? waterPrice,
    RoomStatus? status, int? areaSize,
    List<String>? images, List<String>? amenities,
    String? areaName, String? address,
    double? latitude, double? longitude,
    int? areaId, String? tenant,
  }) {
    return RoomModel(
      roomId:     roomId     ?? this.roomId,
      roomCode:   roomCode   ?? this.roomCode,
      basePrice:  basePrice  ?? this.basePrice,
      elecPrice:  elecPrice  ?? this.elecPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      status:     status     ?? this.status,
      areaSize:   areaSize   ?? this.areaSize,
      images:     images     ?? this.images,
      amenities:  amenities  ?? this.amenities,
      areaName:   areaName   ?? this.areaName,
      address:    address    ?? this.address,
      latitude:   latitude   ?? this.latitude,
      longitude:  longitude  ?? this.longitude,
      areaId:     areaId     ?? this.areaId,
      id:         roomCode   ?? this.id,
      area:       areaName   ?? this.area,
      tenant:     tenant     ?? this.tenant,
      rent:       basePrice  ?? this.rent,
      floor:      this.floor,
    );
  }
}

// ─── TenantModel ──────────────────────────────────────────────────────────────

class TenantModel {
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? idCardNumber;
  final bool isActive;

  // Thông tin hợp đồng hiện tại (nếu có)
  final int? contractId;
  final String? contractCode;
  final int? roomId;
  final String? roomCode;
  final String? areaName;
  /// Enum trạng thái hợp đồng — null nếu chưa có hợp đồng
  final ContractStatus? contractStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int actualRentPrice;

  TenantModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.idCardNumber,
    required this.isActive,
    this.contractId,
    this.contractCode,
    this.roomId,
    this.roomCode,
    this.areaName,
    this.contractStatus,
    this.startDate,
    this.endDate,
    this.actualRentPrice = 0,
  });

  /// Có hợp đồng đang hoạt động không
  bool get hasActiveContract =>
      contractId != null && contractStatus == ContractStatus.active;

  /// Alias để tương thích với các screen cũ
  bool get isActiveContract => hasActiveContract;

  /// Chữ cái đầu của tên (hiển thị avatar)
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.trim().isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Label hiển thị tiếng Việt cho trạng thái hợp đồng
  String get contractStatusLabel => switch (contractStatus) {
    ContractStatus.active     => 'Đang hiệu lực',
    ContractStatus.expired    => 'Đã hết hạn',
    ContractStatus.terminated => 'Đã chấm dứt',
    null                      => '—',
  };

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      userId:           _parseInt(json['userId']),
      fullName:         json['fullName']?.toString() ?? '',
      phoneNumber:      json['phoneNumber']?.toString() ?? '',
      email:            json['email']?.toString(),
      idCardNumber:     json['idCardNumber']?.toString(),
      isActive:         json['isActive'] == true || json['isActive'] == 1,
      contractId:       json['contractId'] != null ? _parseInt(json['contractId']) : null,
      contractCode:     json['contractCode']?.toString(),
      roomId:           json['roomId'] != null ? _parseInt(json['roomId']) : null,
      roomCode:         json['roomCode']?.toString(),
      areaName:         json['areaName']?.toString(),
      contractStatus:   _parseContractStatus(json['contractStatus']),
      startDate:        _parseDate(json['startDate']),
      endDate:          _parseDate(json['endDate']),
      actualRentPrice:  _parseInt(json['actualRentPrice']),
    );
  }
}

// ─── InvoiceModel ─────────────────────────────────────────────────────────────

class InvoiceModel {
  final String id;
  final String room;
  final String tenant;
  final int amount;
  final InvoiceStatus status;
  final String due;

  const InvoiceModel({
    required this.id,
    required this.room,
    required this.tenant,
    required this.amount,
    required this.status,
    required this.due,
  });
}

// ─── ChatMessage ──────────────────────────────────────────────────────────────

class ChatMessage {
  final bool isBot;
  final String text;
  final DateTime time;

  ChatMessage({required this.isBot, required this.text, DateTime? time})
      : time = time ?? DateTime.now();
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

final kRooms = <RoomModel>[
  RoomModel(
    roomId: 1, roomCode: 'R001',
    basePrice: 2010000, elecPrice: 3500, waterPrice: 15000,
    status: RoomStatus.available, areaSize: 21,
    images: [], amenities: [],
    areaName: 'Area 1', address: 'Address 1, Ho Chi Minh City',
    latitude: 10.7001, longitude: 106.6001, areaId: 1,
    id: 'R001', area: 'Area 1', tenant: null, rent: 2010000, floor: 1,
  ),
  RoomModel(
    roomId: 2, roomCode: 'R002',
    basePrice: 2020000, elecPrice: 3500, waterPrice: 15000,
    status: RoomStatus.occupied, areaSize: 22,
    images: [], amenities: [],
    areaName: 'Area 2', address: 'Address 2, Ho Chi Minh City',
    latitude: 10.7002, longitude: 106.6002, areaId: 1,
    id: 'R002', area: 'Area 2', tenant: 'Nguyen A', rent: 2020000, floor: 1,
  ),
];

final kTenants = <TenantModel>[
  TenantModel(
    userId: 1, fullName: 'Nguyen Van A',
    phoneNumber: '0901234567', email: 'a@example.com',
    isActive: true,
    contractId: 1, contractCode: 'HD-2024-001',
    roomId: 2, roomCode: 'R002', areaName: 'Area 2',
    contractStatus: ContractStatus.active,
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
    actualRentPrice: 2020000,
  ),
];

final kInvoices = <InvoiceModel>[
  InvoiceModel(
    id: 'HD001', room: 'R001', tenant: 'Nguyen A',
    amount: 4250000, status: InvoiceStatus.paid, due: '01/07/2025',
  ),
];