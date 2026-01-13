class CreateAndGetSlotHistoryModel {
  final bool success;
  final bool created;
  final SlotData? data;
  final String? message;

  const CreateAndGetSlotHistoryModel({
    required this.success,
    required this.created,
    this.data,
    this.message,
  });

  factory CreateAndGetSlotHistoryModel.fromJson(Map<String, dynamic> json) {
    return CreateAndGetSlotHistoryModel(
      success: json['success'] ?? false,
      created: json['created'] ?? false,
      message: json['message'] ?? "",
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
  final String? status;
  final int? duration;
  final int? totalTime;
  final String? bookingTime;
  final String? expiresAt;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  const SlotData({
    this.id,
    this.slotId,
    this.bookingDate,
    this.time,
    this.courtId,
    this.status,
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
      status: json['status'],
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
    "status": status,
    "duration": duration,
    "totalTime": totalTime,
    "bookingTime": bookingTime,
    "expiresAt": expiresAt,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": version,
  };
}
