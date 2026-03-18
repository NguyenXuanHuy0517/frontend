// lib/models/models.dart

// ── Enums ─────────────────────────────────────────────────────────────────────

enum RoomStatus { available, occupied, maintenance, rented, deposited }

enum InvoiceStatus { paid, pending, overdue }

enum ContractStatus { active, expired, terminated }

// ── RoomModel ─────────────────────────────────────────────────────────────────

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
  final int? areaId;
  final String? areaName;   // nullable — backend có thể null khi chưa gán khu
  final String? address;
  final double? latitude;
  final double? longitude;

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
    this.areaId,
    this.areaName,
    this.address,
    this.latitude,
    this.longitude,
    required this.id,
    required this.area,
    this.tenant,
    required this.rent,
    required this.floor,
  });

  String get areaString => areaName ?? '';

  String get statusString {
    switch (status) {
      case RoomStatus.available:   return 'Trống';
      case RoomStatus.occupied:    return 'Đang thuê';
      case RoomStatus.rented:      return 'Đang thuê';
      case RoomStatus.deposited:   return 'Đặt cọc';
      case RoomStatus.maintenance: return 'Sửa chữa';
    }
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    RoomStatus parseStatus(dynamic s) {
      switch ((s ?? '').toString().toUpperCase()) {
        case 'AVAILABLE':   return RoomStatus.available;
        case 'OCCUPIED':    return RoomStatus.occupied;
        case 'RENTED':      return RoomStatus.rented;
        case 'DEPOSITED':   return RoomStatus.deposited;
        case 'MAINTENANCE': return RoomStatus.maintenance;
        default:            return RoomStatus.available;
      }
    }

    int pi(dynamic v, [int fb = 0]) {
      if (v == null) return fb;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fb;
    }

    double pd(dynamic v, [double fb = 0.0]) {
      if (v == null) return fb;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? fb;
    }

    return RoomModel(
      roomId:    pi(json['roomId']),
      roomCode:  json['roomCode']?.toString() ?? '',
      basePrice:  pi(json['basePrice']),
      elecPrice:  pi(json['elecPrice']),
      waterPrice: pi(json['waterPrice']),
      status:    parseStatus(json['status']),
      areaSize:  pi(json['areaSize']),
      images:    (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      areaId:    json['areaId'] != null ? pi(json['areaId']) : null,
      areaName:  json['areaName']?.toString() ?? '',
      address:   json['address']?.toString() ?? '',
      latitude:  pd(json['latitude']),
      longitude: pd(json['longitude']),
      id:        json['roomCode']?.toString() ?? 'R${json['roomId']}',
      area:      json['areaName']?.toString() ?? '',
      tenant:    null,
      rent:      pi(json['basePrice']),
      floor:     1,
    );
  }

  RoomModel copyWith({
    int? roomId, String? roomCode,
    int? basePrice, int? elecPrice, int? waterPrice,
    RoomStatus? status, int? areaSize,
    List<String>? images, List<String>? amenities,
    int? areaId, String? areaName, String? address,
    double? latitude, double? longitude,
  }) {
    return RoomModel(
      roomId:    roomId    ?? this.roomId,
      roomCode:  roomCode  ?? this.roomCode,
      basePrice:  basePrice  ?? this.basePrice,
      elecPrice:  elecPrice  ?? this.elecPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      status:    status    ?? this.status,
      areaSize:  areaSize  ?? this.areaSize,
      images:    images    ?? this.images,
      amenities: amenities ?? this.amenities,
      areaId:    areaId    ?? this.areaId,
      areaName:  areaName  ?? this.areaName,
      address:   address   ?? this.address,
      latitude:  latitude  ?? this.latitude,
      longitude: longitude ?? this.longitude,
      id:        roomCode  ?? this.id,
      area:      areaName  ?? this.area,
      tenant:    this.tenant,
      rent:      basePrice ?? this.rent,
      floor:     this.floor,
    );
  }
}

// ── TenantModel ───────────────────────────────────────────────────────────────

class TenantModel {
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? idCardNumber;
  final bool isActive;

  // Hợp đồng hiện tại (null nếu chưa có)
  final int? contractId;
  final String? contractCode;
  final ContractStatus? contractStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? actualRentPrice;

  // Phòng đang thuê (null nếu chưa có)
  final int? roomId;
  final String? roomCode;
  final String? areaName;

  TenantModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.idCardNumber,
    required this.isActive,
    this.contractId,
    this.contractCode,
    this.contractStatus,
    this.startDate,
    this.endDate,
    this.actualRentPrice,
    this.roomId,
    this.roomCode,
    this.areaName,
  });

  bool get hasActiveContract => contractStatus == ContractStatus.active;

  String get contractStatusLabel {
    switch (contractStatus) {
      case ContractStatus.active:     return 'Đang hiệu lực';
      case ContractStatus.expired:    return 'Hết hạn';
      case ContractStatus.terminated: return 'Đã chấm dứt';
      case null:                      return 'Chưa có HĐ';
    }
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    ContractStatus? parseContract(dynamic s) {
      switch ((s ?? '').toString().toUpperCase()) {
        case 'ACTIVE':     return ContractStatus.active;
        case 'EXPIRED':    return ContractStatus.expired;
        case 'TERMINATED': return ContractStatus.terminated;
        default:           return null;
      }
    }

    int? pi(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    DateTime? pd(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse('$v'); } catch (_) { return null; }
    }

    return TenantModel(
      userId:       pi(json['userId']) ?? 0,
      fullName:     json['fullName']?.toString() ?? '',
      phoneNumber:  json['phoneNumber']?.toString() ?? '',
      email:        json['email']?.toString(),
      idCardNumber: json['idCardNumber']?.toString(),
      isActive:     json['isActive'] == true,
      contractId:   pi(json['contractId']),
      contractCode: json['contractCode']?.toString(),
      contractStatus: parseContract(json['contractStatus']),
      startDate:    pd(json['startDate']),
      endDate:      pd(json['endDate']),
      actualRentPrice: pi(json['actualRentPrice']),
      roomId:   pi(json['roomId']),
      roomCode: json['roomCode']?.toString(),
      areaName: json['areaName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName':    fullName,
    'phoneNumber': phoneNumber,
    if (email != null)        'email': email,
    if (idCardNumber != null) 'idCardNumber': idCardNumber,
  };
}

// ── InvoiceModel ──────────────────────────────────────────────────────────────

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

// ── ChatMessage ───────────────────────────────────────────────────────────────

class ChatMessage {
  final bool isBot;
  final String text;
  final DateTime time;

  ChatMessage({required this.isBot, required this.text, DateTime? time})
      : time = time ?? DateTime.now();
}

// ── Mock Data ─────────────────────────────────────────────────────────────────

final kRooms = <RoomModel>[
  RoomModel(
    roomId: 1, roomCode: 'R001', basePrice: 2010000, elecPrice: 3500,
    waterPrice: 15000, status: RoomStatus.available, areaSize: 21,
    images: [], amenities: [], areaId: 1,
    areaName: 'Area 1', address: 'Address 1, Ho Chi Minh City',
    latitude: 10.7001, longitude: 106.6001,
    id: 'R001', area: 'Area 1', tenant: null, rent: 2010000, floor: 1,
  ),
  RoomModel(
    roomId: 2, roomCode: 'R002', basePrice: 2020000, elecPrice: 3500,
    waterPrice: 15000, status: RoomStatus.available, areaSize: 22,
    images: [], amenities: [], areaId: 1,
    areaName: 'Area 2', address: 'Address 2, Ho Chi Minh City',
    latitude: 10.7002, longitude: 106.6002,
    id: 'R002', area: 'Area 2', tenant: null, rent: 2020000, floor: 1,
  ),
];

final kInvoices = <InvoiceModel>[
  InvoiceModel(
    id: 'HD001', room: 'R001', tenant: 'Nguyen A',
    amount: 4250000, status: InvoiceStatus.paid, due: '01/07/2025',
  ),
];

final kTenants = <TenantModel>[
  TenantModel(
    userId: 1, fullName: 'Nguyễn Văn An', phoneNumber: '0901234567',
    email: 'an@gmail.com', idCardNumber: '079201012345', isActive: true,
    contractId: 1, contractCode: 'HĐ-2024-001',
    contractStatus: ContractStatus.active,
    startDate: DateTime(2024, 1, 1), endDate: DateTime(2025, 1, 1),
    actualRentPrice: 2020000, roomId: 2, roomCode: 'R002', areaName: 'Khu A',
  ),
  TenantModel(
    userId: 2, fullName: 'Trần Thị Bình', phoneNumber: '0912345678',
    email: 'binh@gmail.com', idCardNumber: '079201098765', isActive: true,
    contractId: 2, contractCode: 'HĐ-2024-002',
    contractStatus: ContractStatus.active,
    startDate: DateTime(2024, 3, 1), endDate: DateTime(2025, 3, 1),
    actualRentPrice: 1800000, roomId: 3, roomCode: 'R003', areaName: 'Khu A',
  ),
  TenantModel(
    userId: 3, fullName: 'Lê Văn Cường', phoneNumber: '0923456789',
    email: null, idCardNumber: null, isActive: false,
    contractId: 3, contractCode: 'HĐ-2023-010',
    contractStatus: ContractStatus.expired,
    startDate: DateTime(2023, 1, 1), endDate: DateTime(2024, 1, 1),
    actualRentPrice: 1500000, roomId: 4, roomCode: 'R004', areaName: 'Khu B',
  ),
];