class ConvertMatchToOpenMatchModel {
  bool? success;
  String? message;
  OpenMatch? openMatch;

  ConvertMatchToOpenMatchModel({
    this.success,
    this.message,
    this.openMatch,
  });

  factory ConvertMatchToOpenMatchModel.fromJson(Map<String, dynamic> json) {
    return ConvertMatchToOpenMatchModel(
      success: json['success'],
      message: json['message'],
      openMatch: json['openMatch'] != null
          ? OpenMatch.fromJson(json['openMatch'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "openMatch": openMatch?.toJson(),
  };
}

//--------------------------------------------------------

class OpenMatch {
  String? clubId;
  List<Slot>? slot;
  String? skillLevel;
  List<String>? skillDetails;
  String? matchDate;
  List<String>? matchTime;
  List<TeamA>? teamA;
  List<String>? teamB;
  String? createdBy;
  String? bookingId;
  String? gender;
  bool? status;
  bool? adminStatus;
  String? matchType;
  bool? matchStatus;
  bool? isActive;
  bool? isDeleted;
  String? id;
  String? createdAt;
  String? updatedAt;
  int? v;

  OpenMatch({
    this.clubId,
    this.slot,
    this.skillLevel,
    this.skillDetails,
    this.matchDate,
    this.matchTime,
    this.teamA,
    this.teamB,
    this.createdBy,
    this.bookingId,
    this.gender,
    this.status,
    this.adminStatus,
    this.matchType,
    this.matchStatus,
    this.isActive,
    this.isDeleted,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory OpenMatch.fromJson(Map<String, dynamic> json) {
    return OpenMatch(
      clubId: json['clubId'],
      skillLevel: json['skillLevel'],
      matchDate: json['matchDate'],
      matchTime: (json['matchTime'] as List?)?.cast<String>(),
      skillDetails: (json['skillDetails'] as List?)?.cast<String>(),
      teamB: (json['teamB'] as List?)?.cast<String>(),
      slot: (json['slot'] as List?)
          ?.map((e) => Slot.fromJson(e))
          .toList(),
      teamA: (json['teamA'] as List?)
          ?.map((e) => TeamA.fromJson(e))
          .toList(),
      createdBy: json['createdBy'],
      bookingId: json['bookingId'],
      gender: json['gender'],
      status: json['status'],
      adminStatus: json['adminStatus'],
      matchType: json['matchType'],
      matchStatus: json['matchStatus'],
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      id: json['_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    "clubId": clubId,
    "skillLevel": skillLevel,
    "skillDetails": skillDetails,
    "matchDate": matchDate,
    "matchTime": matchTime,
    "slot": slot?.map((e) => e.toJson()).toList(),
    "teamA": teamA?.map((e) => e.toJson()).toList(),
    "teamB": teamB,
    "createdBy": createdBy,
    "bookingId": bookingId,
    "gender": gender,
    "status": status,
    "adminStatus": adminStatus,
    "matchType": matchType,
    "matchStatus": matchStatus,
    "isActive": isActive,
    "isDeleted": isDeleted,
    "_id": id,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
  };
}

//--------------------------------------------------------

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  List<SlotTimes>? slotTimes;

  Slot({
    this.slotId,
    this.courtName,
    this.courtId,
    this.slotTimes,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      slotId: json['slotId'],
      courtName: json['courtName'],
      courtId: json['courtId'],
      slotTimes: (json['slotTimes'] as List?)
          ?.map((e) => SlotTimes.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "slotId": slotId,
    "courtName": courtName,
    "courtId": courtId,
    "slotTimes": slotTimes?.map((e) => e.toJson()).toList(),
  };
}

//--------------------------------------------------------

class SlotTimes {
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;

  SlotTimes({
    this.time,
    this.amount,
    this.status,
    this.availabilityStatus,
  });

  factory SlotTimes.fromJson(Map<String, dynamic> json) {
    return SlotTimes(
      time: json['time'],
      amount: json['amount'],
      status: json['status'],
      availabilityStatus: json['availabilityStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    "time": time,
    "amount": amount,
    "status": status,
    "availabilityStatus": availabilityStatus,
  };
}

//--------------------------------------------------------

class TeamA {
  String? userId;
  String? joinedAt;
  String? id;

  TeamA({
    this.userId,
    this.joinedAt,
    this.id,
  });

  factory TeamA.fromJson(Map<String, dynamic> json) {
    return TeamA(
      userId: json['userId'],
      joinedAt: json['joinedAt'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "joinedAt": joinedAt,
    "_id": id,
  };
}
