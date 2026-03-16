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
    // legacy
    required this.id,
    required this.area,
    this.tenant,
    required this.rent,
    required this.floor,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    RoomStatus parseStatus(String s) {
      switch (s.toUpperCase()) {
        case 'AVAILABLE': return RoomStatus.available;
        case 'OCCUPIED':  return RoomStatus.occupied;
        case 'MAINTENANCE': return RoomStatus.maintenance;
        default: return RoomStatus.available;
      }
    }

    return RoomModel(
      roomId: json['roomId'] ?? 0,
      roomCode: json['roomCode'] ?? '',
      basePrice: json['basePrice'] ?? 0,
      elecPrice: json['elecPrice'] ?? 0,
      waterPrice: json['waterPrice'] ?? 0,
      status: parseStatus(json['status'] ?? 'AVAILABLE'),
      areaSize: json['areaSize'] ?? 0,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      areaName: json['areaName'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude']}') ?? 0.0,
      // legacy UI fields derived from API
      id: json['roomCode'] != null ? json['roomCode'].toString() : 'R${json['roomId']}',
      area: json['areaName'] ?? '',
      tenant: null,
      rent: json['basePrice'] ?? 0,
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

// ─── Mock Data (kept for local dev / fallback) ───────────────────────────────

final kRooms = <RoomModel>[
  RoomModel(roomId: 1, roomCode: 'R001', basePrice: 2010000, elecPrice: 3500, waterPrice: 15000, status: RoomStatus.available, areaSize: 21, images: [], amenities: [], areaName: 'Area 1', address: 'Address 1, Ho Chi Minh City', latitude: 10.7001, longitude: 106.6001, id: 'R001', area: 'Area 1', tenant: null, rent: 2010000, floor: 1),
  RoomModel(roomId: 2, roomCode: 'R002', basePrice: 2020000, elecPrice: 3500, waterPrice: 15000, status: RoomStatus.available, areaSize: 22, images: [], amenities: [], areaName: 'Area 2', address: 'Address 2, Ho Chi Minh City', latitude: 10.7002, longitude: 106.6002, id: 'R002', area: 'Area 2', tenant: null, rent: 2020000, floor: 1),
];

final kInvoices = <InvoiceModel>[
  InvoiceModel(id: 'HD001', room: 'R001', tenant: 'Nguyen A', amount: 4250000, status: InvoiceStatus.paid, due: '01/07/2025'),
];
