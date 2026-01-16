class GetRequestPlayersOpenMatchModel {
  final String? message;
  final List<Requests>? requests;

  GetRequestPlayersOpenMatchModel({
    this.message,
    this.requests,
  });

  factory GetRequestPlayersOpenMatchModel.fromJson(Map<String, dynamic> json) {
    return GetRequestPlayersOpenMatchModel(
      message: json['message']?.toString(),
      requests: json['requests'] != null
          ? List<Requests>.from(
        json['requests'].map((x) => Requests.fromJson(x)),
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'requests': requests?.map((e) => e.toJson()).toList(),
    };
  }
}

/* -------------------------------------------------------------------------- */

class Requests {
  final String? id;
  final String? type; // request | invitation
  final String? status;
  final String? preferredTeam;
  final String? bookingId;
  final String? level;

  final String? matchIdString;
  final MatchId? match;

  final RequesterId? requester;
  final RequesterId? matchCreator;
  final String? playerId;

  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Requests({
    this.id,
    this.type,
    this.status,
    this.preferredTeam,
    this.bookingId,
    this.level,
    this.matchIdString,
    this.match,
    this.requester,
    this.matchCreator,
    this.playerId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Requests.fromJson(Map<String, dynamic> json) {
    return Requests(
      id: json['_id']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      preferredTeam: json['preferredTeam']?.toString(),
      bookingId: json['bookingId']?.toString(),
      level: json['level']?.toString(),
      matchIdString: json['matchId'] is String ? json['matchId'] : null,
      match: json['matchId'] is Map<String, dynamic>
          ? MatchId.fromJson(json['matchId'])
          : null,
      requester: json['requesterId'] is Map<String, dynamic>
          ? RequesterId.fromJson(json['requesterId'])
          : null,
      matchCreator: json['matchCreatorId'] is Map<String, dynamic>
          ? RequesterId.fromJson(json['matchCreatorId'])
          : null,
      playerId: json['playerId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'status': status,
      'preferredTeam': preferredTeam,
      'bookingId': bookingId,
      'level': level,
      'matchId': match != null ? match!.toJson() : matchIdString,
      'requesterId': requester?.toJson(),
      'matchCreatorId': matchCreator?.toJson(),
      'playerId': playerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

/* -------------------------------------------------------------------------- */

class MatchId {
  final String? id;
  final String? matchDate;
  final List<String>? matchTime;
  final List<TeamA>? teamA;
  final List<TeamB>? teamB;
  final ClubId? club;

  final String? matchType;
  final String? skillLevel;
  final String? gender;

  MatchId({
    this.id,
    this.matchDate,
    this.matchTime,
    this.teamA,
    this.teamB,
    this.club,
    this.matchType,
    this.skillLevel,
    this.gender,
  });

  factory MatchId.fromJson(Map<String, dynamic> json) {
    return MatchId(
      id: json['_id']?.toString(),
      matchDate: json['matchDate']?.toString(),
      matchTime: json['matchTime'] != null
          ? List<String>.from(json['matchTime'].map((x) => x.toString()))
          : null,
      teamA: json['teamA'] != null
          ? List<TeamA>.from(json['teamA'].map((x) => TeamA.fromJson(x)))
          : null,
      teamB: json['teamB'] != null
          ? List<TeamB>.from(json['teamB'].map((x) => TeamB.fromJson(x)))
          : null,
      club: json['clubId'] is Map<String, dynamic>
          ? ClubId.fromJson(json['clubId'])
          : null,
      matchType: json['matchType']?.toString(),
      skillLevel: json['skillLevel']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matchDate': matchDate,
      'matchTime': matchTime,
      'teamA': teamA?.map((e) => e.toJson()).toList(),
      'teamB': teamB?.map((e) => e.toJson()).toList(),
      'clubId': club?.toJson(),
      'matchType': matchType,
      'skillLevel': skillLevel,
      'gender': gender,
    };
  }
}

/* -------------------------------------------------------------------------- */

class TeamA {
  final RequesterId? user;
  final String? joinedAt;
  final String? id;

  TeamA({
    this.user,
    this.joinedAt,
    this.id,
  });

  factory TeamA.fromJson(Map<String, dynamic> json) {
    return TeamA(
      user: json['userId'] != null
          ? RequesterId.fromJson(json['userId'])
          : null,
      joinedAt: json['joinedAt']?.toString(),
      id: json['_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': user?.toJson(),
      'joinedAt': joinedAt,
    };
  }
}

/* -------------------------------------------------------------------------- */

class TeamB {
  final RequesterId? user;
  final String? joinedAt;
  final String? id;

  TeamB({
    this.user,
    this.joinedAt,
    this.id,
  });

  factory TeamB.fromJson(Map<String, dynamic> json) {
    return TeamB(
      user: json['userId'] != null
          ? RequesterId.fromJson(json['userId'])
          : null,
      joinedAt: json['joinedAt']?.toString(),
      id: json['_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': user?.toJson(),
      'joinedAt': joinedAt,
    };
  }
}

/* -------------------------------------------------------------------------- */

class RequesterId {
  final String? id;
  final String? email;
  final int? phoneNumber;
  final String? name;
  final String? lastName;
  final String? profilePic;
  final String? xpPoints;
  final String? gender;

  RequesterId({
    this.id,
    this.email,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.profilePic,
    this.xpPoints,
    this.gender,
  });

  factory RequesterId.fromJson(Map<String, dynamic> json) {
    return RequesterId(
      id: json['_id']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber'] is int
          ? json['phoneNumber']
          : int.tryParse(json['phoneNumber']?.toString() ?? ''),
      name: json['name']?.toString(),
      lastName: json['lastName']?.toString(),
      profilePic: json['profilePic']?.toString(),
      xpPoints: json['xpPoints']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'lastName': lastName,
      'profilePic': profilePic,
      'xpPoints': xpPoints,
      'gender': gender,
    };
  }
}

/* -------------------------------------------------------------------------- */

class ClubId {
  final String? id;
  final String? ownerId;
  final String? clubName;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final int? courtCount;
  final List<String>? courtType;
  final List<String>? features;
  final Location? location;

  final bool? isActive;
  final bool? isVerified;
  final bool? isFeatured;
  final bool? isDeleted;

  final String? createdAt;
  final String? updatedAt;

  ClubId({
    this.id,
    this.ownerId,
    this.clubName,
    this.description,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.courtCount,
    this.courtType,
    this.features,
    this.location,
    this.isActive,
    this.isVerified,
    this.isFeatured,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory ClubId.fromJson(Map<String, dynamic> json) {
    return ClubId(
      id: json['_id']?.toString(),
      ownerId: json['ownerId']?.toString(),
      clubName: json['clubName']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: json['zipCode']?.toString(),
      courtCount: json['courtCount'] is int
          ? json['courtCount']
          : int.tryParse(json['courtCount']?.toString() ?? '0'),
      courtType: json['courtType'] != null
          ? List<String>.from(json['courtType'].map((x) => x.toString()))
          : null,
      features: json['features'] != null
          ? List<String>.from(json['features'].map((x) => x.toString()))
          : null,
      location: json['location'] is Map<String, dynamic>
          ? Location.fromJson(json['location'])
          : null,
      isActive: json['isActive'] as bool?,
      isVerified: json['isVerified'] as bool?,
      isFeatured: json['isFeatured'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'clubName': clubName,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'courtCount': courtCount,
      'courtType': courtType,
      'features': features,
      'location': location?.toJson(),
      'isActive': isActive,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/* -------------------------------------------------------------------------- */

class Location {
  final String? type;
  final List<double>? coordinates;

  Location({
    this.type,
    this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type']?.toString(),
      coordinates: json['coordinates'] != null
          ? List<double>.from(
        json['coordinates'].map((x) => (x as num).toDouble()),
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}
