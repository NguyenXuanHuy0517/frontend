// lib/models/models.dart

// FIX: Thêm rented & deposited để đồng bộ với dashboard, room_detail, utilities, shared_widgets
enum RoomStatus { available, occupied, maintenance, rented, deposited }

enum InvoiceStatus { paid, pending, overdue }

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
  final String areaName;
  final String address;
  final double latitude;
  final double longitude;

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
    required this.areaName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.id,
    required this.area,
    this.tenant,
    required this.rent,
    required this.floor,
  });

  /// FIX: Getter statusString dùng trong room_detail_screen
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

    // FIX: Parse BigDecimal từ backend (có thể là int, double, hoặc num)
    int parseIntSafe(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double parseDoubleSafe(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    return RoomModel(
      roomId:     parseIntSafe(json['roomId']),
      roomCode:   json['roomCode']?.toString() ?? '',
      basePrice:  parseIntSafe(json['basePrice']),
      elecPrice:  parseIntSafe(json['elecPrice']),
      waterPrice: parseIntSafe(json['waterPrice']),
      status:     parseStatus(json['status']),
      areaSize:   parseIntSafe(json['areaSize']),
      images:     (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities:  (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      areaId:     json['areaId'] != null ? parseIntSafe(json['areaId']) : null,
      areaName:   json['areaName']?.toString() ?? '',
      address:    json['address']?.toString() ?? '',
      latitude:   parseDoubleSafe(json['latitude']),
      longitude:  parseDoubleSafe(json['longitude']),
      id:         json['roomCode']?.toString() ?? 'R${json['roomId']}',
      area:       json['areaName']?.toString() ?? '',
      tenant:     null,
      rent:       parseIntSafe(json['basePrice']),
      floor:      1,
    );
  }

  RoomModel copyWith({
    int? roomId, String? roomCode, int? basePrice, int? elecPrice,
    int? waterPrice, RoomStatus? status, int? areaSize,
    List<String>? images, List<String>? amenities, int? areaId,
    String? areaName, String? address, double? latitude, double? longitude,
  }) {
    return RoomModel(
      roomId:     roomId ?? this.roomId,
      roomCode:   roomCode ?? this.roomCode,
      basePrice:  basePrice ?? this.basePrice,
      elecPrice:  elecPrice ?? this.elecPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      status:     status ?? this.status,
      areaSize:   areaSize ?? this.areaSize,
      images:     images ?? this.images,
      amenities:  amenities ?? this.amenities,
      areaId:     areaId ?? this.areaId,
      areaName:   areaName ?? this.areaName,
      address:    address ?? this.address,
      latitude:   latitude ?? this.latitude,
      longitude:  longitude ?? this.longitude,
      id:         roomCode ?? this.id,
      area:       areaName ?? this.area,
      tenant:     this.tenant,
      rent:       basePrice ?? this.rent,
      floor:      this.floor,
    );
  }
}

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
    roomId: 1, roomCode: 'R001', basePrice: 2010000, elecPrice: 3500,
    waterPrice: 15000, status: RoomStatus.available, areaSize: 21,
    images: [], amenities: [], areaId: 1, areaName: 'Khu A',
    address: '123 Đường ABC, Quận 1, TP.HCM',
    latitude: 10.7001, longitude: 106.6001,
    id: 'R001', area: 'Khu A', tenant: null, rent: 2010000, floor: 1,
  ),
  RoomModel(
    roomId: 2, roomCode: 'R002', basePrice: 2020000, elecPrice: 3500,
    waterPrice: 15000, status: RoomStatus.occupied, areaSize: 22,
    images: [], amenities: [], areaId: 1, areaName: 'Khu A',
    address: '123 Đường ABC, Quận 1, TP.HCM',
    latitude: 10.7002, longitude: 106.6002,
    id: 'R002', area: 'Khu A', tenant: 'Nguyễn Văn A', rent: 2020000, floor: 1,
  ),
];

final kInvoices = <InvoiceModel>[
  InvoiceModel(
    id: 'HD001', room: 'R001', tenant: 'Nguyen A',
    amount: 4250000, status: InvoiceStatus.paid, due: '01/07/2025',
  ),
];