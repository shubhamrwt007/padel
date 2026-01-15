class UpdateBookingModel {
  final bool? success;
  final String? message;
  final BookingData? data;

  UpdateBookingModel({this.success, this.message, this.data});

  factory UpdateBookingModel.fromJson(Map<String, dynamic> json) {
    return UpdateBookingModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? BookingData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
  };
}

/* ---------------- DATA ---------------- */

class BookingData {
  final String? id;
  final String? userId;
  final String? registerClubId;
  final int? totalAmount;
  final String? bookingDate;
  final String? bookingStatus;
  final String? bookingType;
  final List<Slot>? slots;
  final String? createdAt;
  final String? ownerId;
  final String? updatedAt;
  final List<String>? playerIds;
  final int? duration;
  final int? totalTime;
  final String? bookingTime;
  final String? matchType;
  final bool? matchStatus;
  final List<TeamMember>? teamA;
  final List<TeamMember>? teamB;
  final int? v;

  BookingData({
    this.id,
    this.userId,
    this.registerClubId,
    this.totalAmount,
    this.bookingDate,
    this.bookingStatus,
    this.bookingType,
    this.slots,
    this.createdAt,
    this.ownerId,
    this.updatedAt,
    this.playerIds,
    this.duration,
    this.totalTime,
    this.bookingTime,
    this.matchType,
    this.matchStatus,
    this.teamA,
    this.teamB,
    this.v,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['_id'],
      userId: json['userId'],
      registerClubId: json['register_club_id'],
      totalAmount: json['totalAmount'],
      bookingDate: json['bookingDate'],
      bookingStatus: json['bookingStatus'],
      bookingType: json['bookingType'],
      slots: (json['slot'] as List?)
          ?.map((e) => Slot.fromJson(e))
          .toList(),
      createdAt: json['createdAt'],
      ownerId: json['ownerId'],
      updatedAt: json['updatedAt'],
      playerIds: (json['playerIds'] as List?)?.cast<String>(),
      duration: json['duration'],
      totalTime: json['totalTime'],
      bookingTime: json['bookingTime'],
      matchType: json['matchType'],
      matchStatus: json['matchStatus'],
      teamA: (json['teamA'] as List?)
          ?.map((e) => TeamMember.fromJson(e))
          .toList(),
      teamB: (json['teamB'] as List?)
          ?.map((e) => TeamMember.fromJson(e))
          .toList(),
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'register_club_id': registerClubId,
    'totalAmount': totalAmount,
    'bookingDate': bookingDate,
    'bookingStatus': bookingStatus,
    'bookingType': bookingType,
    'slot': slots?.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
    'ownerId': ownerId,
    'updatedAt': updatedAt,
    'playerIds': playerIds,
    'duration': duration,
    'totalTime': totalTime,
    'bookingTime': bookingTime,
    'matchType': matchType,
    'matchStatus': matchStatus,
    'teamA': teamA?.map((e) => e.toJson()).toList(),
    'teamB': teamB?.map((e) => e.toJson()).toList(),
    '__v': v,
  };
}

/* ---------------- SLOT ---------------- */

class Slot {
  final String? slotId;
  final String? courtName;
  final String? courtId;
  final String? bookingDate;
  final List<SlotTime>? slotTimes;

  Slot({
    this.slotId,
    this.courtName,
    this.courtId,
    this.bookingDate,
    this.slotTimes,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      slotId: json['slotId'],
      courtName: json['courtName'],
      courtId: json['courtId'],
      bookingDate: json['bookingDate'],
      slotTimes: (json['slotTimes'] as List?)
          ?.map((e) => SlotTime.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'courtName': courtName,
    'courtId': courtId,
    'bookingDate': bookingDate,
    'slotTimes': slotTimes?.map((e) => e.toJson()).toList(),
  };
}

/* ---------------- SLOT TIME ---------------- */

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

/* ---------------- TEAM ---------------- */

class TeamMember {
  final String? userId;
  final String? joinedAt;
  final String? id;

  TeamMember({this.userId, this.joinedAt, this.id});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'],
      joinedAt: json['joinedAt'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'joinedAt': joinedAt,
    '_id': id,
  };
}
