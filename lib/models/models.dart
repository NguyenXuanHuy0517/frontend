// lib/models/models.dart

enum RoomStatus { available, occupied, maintenance }

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

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // ── Robust numeric parsers ──────────────────────────────────────────────
    // Backend trả BigDecimal/double (vd: 3500.00), Flutter cần int
    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.split('.').first) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    // ── Status ──────────────────────────────────────────────────────────────
    RoomStatus parseStatus(dynamic s) {
      final str = (s ?? '').toString().toUpperCase();
      switch (str) {
        case 'AVAILABLE':   return RoomStatus.available;
        case 'OCCUPIED':
        case 'RENTED':      return RoomStatus.occupied;
        case 'MAINTENANCE':
        case 'DEPOSITED':   return RoomStatus.maintenance;
        default:            return RoomStatus.available;
      }
    }

    // ── Images & Amenities ──────────────────────────────────────────────────
    // Backend có thể trả List hoặc comma-separated String
    List<String> parseStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) {
        return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final roomId   = parseInt(json['roomId']);
    final roomCode = json['roomCode']?.toString() ?? '';
    final basePrice = parseInt(json['basePrice']);
    final elecPrice = parseInt(json['elecPrice']);
    final waterPrice = parseInt(json['waterPrice']);
    final areaSize  = parseInt(json['areaSize']);
    final status    = parseStatus(json['status']);
    final images    = parseStringList(json['images']);
    final amenities = parseStringList(json['amenities']);
    final areaName  = json['areaName']?.toString() ?? '';
    final address   = json['address']?.toString() ?? '';
    final latitude  = parseDouble(json['latitude']);
    final longitude = parseDouble(json['longitude']);

    return RoomModel(
      roomId: roomId,
      roomCode: roomCode,
      basePrice: basePrice,
      elecPrice: elecPrice,
      waterPrice: waterPrice,
      status: status,
      areaSize: areaSize,
      images: images,
      amenities: amenities,
      areaName: areaName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      // legacy UI fields
      id: roomCode.isNotEmpty ? roomCode : 'R$roomId',
      area: areaName,
      tenant: null,
      rent: basePrice,
      floor: 1,
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

// ─── Mock / Fallback Data ─────────────────────────────────────────────────────

final kRooms = <RoomModel>[
  RoomModel(
    roomId: 1, roomCode: 'R001', basePrice: 2010000,
    elecPrice: 3500, waterPrice: 15000,
    status: RoomStatus.available, areaSize: 21,
    images: [], amenities: [],
    areaName: 'Khu A', address: 'Hồ Chí Minh',
    latitude: 10.7001, longitude: 106.6001,
    id: 'R001', area: 'Khu A', tenant: null, rent: 2010000, floor: 1,
  ),
];

final kInvoices = <InvoiceModel>[
  InvoiceModel(
    id: 'HD001', room: 'R001', tenant: 'Nguyễn A',
    amount: 4250000, status: InvoiceStatus.paid, due: '01/07/2025',
  ),
];