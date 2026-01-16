/* ================= Respond To Booking Request ================= */

class RespondToBookingRequestModel {
  final String? message;
  final Request? request;

  const RespondToBookingRequestModel({this.message, this.request});

  factory RespondToBookingRequestModel.fromJson(Map<String, dynamic> json) {
    return RespondToBookingRequestModel(
      message: json['message'],
      request:
      json['request'] != null ? Request.fromJson(json['request']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'request': request?.toJson(),
  };
}

/* ================= Request ================= */

class Request {
  final String? id;
  final String? matchCreatorId;
  final User? player;
  final Booking? booking;
  final String? preferredTeam;
  final String? status;
  final String? type;
  final String? bookingType;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  const Request({
    this.id,
    this.matchCreatorId,
    this.player,
    this.booking,
    this.preferredTeam,
    this.status,
    this.type,
    this.bookingType,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['_id'],
      matchCreatorId: json['matchCreatorId'],
      player:
      json['playerId'] != null ? User.fromJson(json['playerId']) : null,
      booking:
      json['bookingId'] != null ? Booking.fromJson(json['bookingId']) : null,
      preferredTeam: json['preferredTeam'],
      status: json['status'],
      type: json['type'],
      bookingType: json['bookingType'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'matchCreatorId': matchCreatorId,
    'playerId': player?.toJson(),
    'bookingId': booking?.toJson(),
    'preferredTeam': preferredTeam,
    'status': status,
    'type': type,
    'bookingType': bookingType,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

/* ================= User ================= */

class User {
  final String? id;
  final String? phoneNumber;  // Keep as String for display
  final String? email;
  final String? name;
  final String? city;

  const User({
    this.id,
    this.phoneNumber,
    this.email,
    this.name,
    this.city,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      phoneNumber: json['phoneNumber']?.toString(), // ✅ Convert to String
      email: json['email'],
      name: json['name'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'phoneNumber': phoneNumber,
    'email': email,
    'name': name,
    'city': city,
  };
}

/* ================= Booking ================= */

class Booking {
  final String? id;
  final String? bookingDate;
  final String? bookingTime;
  final int? totalAmount;
  final int? duration;
  final int? totalTime;
  final String? matchType;
  final String? bookingStatus;
  final List<TeamMember>? teamA;
  final List<TeamMember>? teamB;

  const Booking({
    this.id,
    this.bookingDate,
    this.bookingTime,
    this.totalAmount,
    this.duration,
    this.totalTime,
    this.matchType,
    this.bookingStatus,
    this.teamA,
    this.teamB,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      bookingDate: json['bookingDate'],
      bookingTime: json['bookingTime'],
      totalAmount: json['totalAmount'],
      duration: json['duration'],
      totalTime: json['totalTime'],
      matchType: json['matchType'],
      bookingStatus: json['bookingStatus'],
      teamA: json['teamA'] != null
          ? List<TeamMember>.from(
        json['teamA'].map((x) => TeamMember.fromJson(x)),
      )
          : null,
      teamB: json['teamB'] != null
          ? List<TeamMember>.from(
        json['teamB'].map((x) => TeamMember.fromJson(x)),
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'bookingDate': bookingDate,
    'bookingTime': bookingTime,
    'totalAmount': totalAmount,
    'duration': duration,
    'totalTime': totalTime,
    'matchType': matchType,
    'bookingStatus': bookingStatus,
    'teamA': teamA?.map((e) => e.toJson()).toList(),
    'teamB': teamB?.map((e) => e.toJson()).toList(),
  };
}

/* ================= Team Member ================= */

class TeamMember {
  final String? userId;
  final String? joinedAt;
  final String? id;

  const TeamMember({
    this.userId,
    this.joinedAt,
    this.id,
  });

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
