class UpdateNewCourtBookingModel {
  final int? status;
  final String? message;
  final BookingData? data;

  UpdateNewCourtBookingModel({this.status,this.message, this.data});

  factory UpdateNewCourtBookingModel.fromJson(Map<String, dynamic> json) {
    return UpdateNewCourtBookingModel(
      status: json['status'],
      message: json['message'],
      data:
      json['data'] != null ? BookingData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}
class BookingData {
  final String? id;
  final String? clubId;
  final List<Slot>? slot;
  final String? skillLevel;
  final String? matchDate;
  final List<String>? matchTime;
  final List<TeamMember>? teamA;
  final List<TeamMember>? teamB;
  final String? createdBy;
  final String? gender;
  final bool? status;
  final bool? adminStatus;
  final String? matchType;
  final bool? matchStatus;
  final String? openMatchStatus;
  final int? totalMatchPayment;
  final String? startTime;
  final String? endTime;
  final bool? isActive;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  BookingData({
    this.id,
    this.clubId,
    this.slot,
    this.skillLevel,
    this.matchDate,
    this.matchTime,
    this.teamA,
    this.teamB,
    this.createdBy,
    this.gender,
    this.status,
    this.adminStatus,
    this.matchType,
    this.matchStatus,
    this.openMatchStatus,
    this.totalMatchPayment,
    this.startTime,
    this.endTime,
    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['_id'],
      clubId: json['clubId'],
      slot: (json['slot'] as List?)
          ?.map((e) => Slot.fromJson(e))
          .toList(),
      skillLevel: json['skillLevel'],
      matchDate: json['matchDate'],
      matchTime: List<String>.from(json['matchTime'] ?? []),
      teamA: (json['teamA'] as List?)
          ?.map((e) => TeamMember.fromJson(e))
          .toList(),
      teamB: (json['teamB'] as List?)
          ?.map((e) => TeamMember.fromJson(e))
          .toList(),
      createdBy: json['createdBy'],
      gender: json['gender'],
      status: json['status'],
      adminStatus: json['adminStatus'],
      matchType: json['matchType'],
      matchStatus: json['matchStatus'],
      openMatchStatus: json['openMatchStatus'],
      totalMatchPayment: json['totalMatchPayment'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      version: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'clubId': clubId,
    'slot': slot?.map((e) => e.toJson()).toList(),
    'skillLevel': skillLevel,
    'matchDate': matchDate,
    'matchTime': matchTime,
    'teamA': teamA?.map((e) => e.toJson()).toList(),
    'teamB': teamB?.map((e) => e.toJson()).toList(),
    'createdBy': createdBy,
    'gender': gender,
    'status': status,
    'adminStatus': adminStatus,
    'matchType': matchType,
    'matchStatus': matchStatus,
    'openMatchStatus': openMatchStatus,
    'totalMatchPayment': totalMatchPayment,
    'startTime': startTime,
    'endTime': endTime,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': version,
  };
}
class Slot {
  final String? slotId;
  final String? courtName;
  final String? courtId;
  final List<SlotTime>? slotTimes;

  Slot({this.slotId, this.courtName, this.courtId, this.slotTimes});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      slotId: json['slotId'],
      courtName: json['courtName'],
      courtId: json['courtId'],
      slotTimes: (json['slotTimes'] as List?)
          ?.map((e) => SlotTime.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'courtName': courtName,
    'courtId': courtId,
    'slotTimes': slotTimes?.map((e) => e.toJson()).toList(),
  };
}
class SlotTime {
  final String? time;
  final int? amount;
  final String? status;
  final String? availabilityStatus;

  SlotTime({this.time, this.amount, this.status, this.availabilityStatus});

  factory SlotTime.fromJson(Map<String, dynamic> json) {
    return SlotTime(
      time: json['time'],
      amount: json['amount'],
      status: json['status'],
      availabilityStatus: json['availabilityStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'amount': amount,
    'status': status,
    'availabilityStatus': availabilityStatus,
  };
}
class TeamMember {
  final String? userId;
  final int? amountPaid;
  final bool? paidStatus;
  final String? paidAt;
  final String? joinedAt;
  final String? id;

  TeamMember({
    this.userId,
    this.amountPaid,
    this.paidStatus,
    this.paidAt,
    this.joinedAt,
    this.id,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'],
      amountPaid: json['amountPaid'],
      paidStatus: json['paidStatus'],
      paidAt: json['paidAt'],
      joinedAt: json['joinedAt'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amountPaid': amountPaid,
    'paidStatus': paidStatus,
    'paidAt': paidAt,
    'joinedAt': joinedAt,
    '_id': id,
  };
}
