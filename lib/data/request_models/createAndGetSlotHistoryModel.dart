class CreateAndGetSlotHistoryResponse {
  final bool success;
  final int count;
  final List<CreateAndGetSlotHistoryModel> data;

  CreateAndGetSlotHistoryResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory CreateAndGetSlotHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CreateAndGetSlotHistoryResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => CreateAndGetSlotHistoryModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "count": count,
    "data": data.map((e) => e.toJson()).toList(),
  };
}

class CreateAndGetSlotHistoryModel {
  final bool success;
  final bool created;
  final String? message;
  final SlotData? data;

  CreateAndGetSlotHistoryModel({
    required this.success,
    required this.created,
    this.message,
    this.data,
  });

  factory CreateAndGetSlotHistoryModel.fromJson(Map<String, dynamic> json) {
    return CreateAndGetSlotHistoryModel(
      success: json['success'] ?? false,
      created: json['created'] ?? false,
      message: json['message'],
      data: json['data'] != null ? SlotData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "created": created,
    "message": message,
    "data": data?.toJson(),
  };
}

class SlotData {
  final String? id;
  final String? slotId;
  final String? bookingDate;
  final String? time;
  final String? courtId;
  final int? duration;
  final int? totalTime;
  final String? bookingTime;
  final String? expiresAt;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  SlotData({
    this.id,
    this.slotId,
    this.bookingDate,
    this.time,
    this.courtId,
    this.duration,
    this.totalTime,
    this.bookingTime,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory SlotData.fromJson(Map<String, dynamic> json) {
    return SlotData(
      id: json['_id'],
      slotId: json['slotId'],
      bookingDate: json['bookingDate'],
      time: json['time'],
      courtId: json['courtId'],
      duration: json['duration'],
      totalTime: json['totalTime'],
      bookingTime: json['bookingTime'],
      expiresAt: json['expiresAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      version: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "slotId": slotId,
    "bookingDate": bookingDate,
    "time": time,
    "courtId": courtId,
    "duration": duration,
    "totalTime": totalTime,
    "bookingTime": bookingTime,
    "expiresAt": expiresAt,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": version,
  };
}
