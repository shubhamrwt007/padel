class ProfileModel {
  final String? status;
  final String? message;
  final ProfileResponse? response;
  final bool? existsOpenMatchData;

  const ProfileModel({
    this.status,
    this.message,
    this.response,
    this.existsOpenMatchData,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      status: json['status'],
      message: json['message'],
      response: json['response'] != null
          ? ProfileResponse.fromJson(json['response'])
          : null,
      existsOpenMatchData: json['existsOpenMatchData'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'response': response?.toJson(),
    'existsOpenMatchData': existsOpenMatchData,
  };
}

class ProfileResponse {
  final String? sId;
  final String? name;
  final String? lastName;
  final String? email;
  final String? profilePic;
  final String? playerLevel;
  final String? level;
  final String? role;
  final String? countryCode;
  final int? phoneNumber;
  final String? dob;
  final String? gender;

  final Location? location;
  final City? city;

  final int? totalMatchesPlayed;
  final int? totalWins;
  final int? simpleMatchCount;
  final int? openMatchCount;
  final int? americanMatchCount;
  final int? rank;
  final int? winRatio;
  final int? currentWinStreak;
  final int? currentLoseStreak;

  final dynamic xpPoints;
  final List<String>? fcmTokens;
  final List<dynamic>? recentMatches;

  final bool? isActive;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const ProfileResponse({
    this.sId,
    this.name,
    this.lastName,
    this.email,
    this.profilePic,
    this.playerLevel,
    this.level,
    this.role,
    this.countryCode,
    this.phoneNumber,
    this.dob,
    this.gender,
    this.location,
    this.city,
    this.totalMatchesPlayed,
    this.totalWins,
    this.simpleMatchCount,
    this.openMatchCount,
    this.americanMatchCount,
    this.rank,
    this.winRatio,
    this.currentWinStreak,
    this.currentLoseStreak,
    this.xpPoints,
    this.fcmTokens,
    this.recentMatches,
    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      sId: json['_id'],
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      profilePic: json['profilePic'],
      playerLevel: json['playerLevel'],
      level: json['level'],
      role: json['role'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber']?.toInt(),
      dob: json['dob'],
      gender: json['gender'],
      location:
      json['location'] != null ? Location.fromJson(json['location']) : null,
      city: json['city'] != null ? City.fromJson(json['city']) : null,
      totalMatchesPlayed: json['totalMatchesPlayed']?.toInt(),
      totalWins: json['totalWins']?.toInt(),
      simpleMatchCount: json['simpleMatchCount']?.toInt(),
      openMatchCount: json['openMatchCount']?.toInt(),
      americanMatchCount: json['americanMatchCount']?.toInt(),
      rank: json['rank']?.toInt(),
      winRatio: json['winRatio']?.toInt(),
      currentWinStreak: json['currentWinStreak']?.toInt(),
      currentLoseStreak: json['currentLoseStreak']?.toInt(),
      xpPoints: json['xpPoints'],
      fcmTokens: (json['fcmTokens'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      recentMatches: json['recentMatches'] as List?,
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'name': name,
    'lastName': lastName,
    'email': email,
    'profilePic': profilePic,
    'playerLevel': playerLevel,
    'level': level,
    'role': role,
    'countryCode': countryCode,
    'phoneNumber': phoneNumber,
    'dob': dob,
    'gender': gender,
    'location': location?.toJson(),
    'city': city?.toJson(),
    'totalMatchesPlayed': totalMatchesPlayed,
    'totalWins': totalWins,
    'simpleMatchCount': simpleMatchCount,
    'openMatchCount': openMatchCount,
    'americanMatchCount': americanMatchCount,
    'rank': rank,
    'winRatio': winRatio,
    'currentWinStreak': currentWinStreak,
    'currentLoseStreak': currentLoseStreak,
    'xpPoints': xpPoints,
    'fcmTokens': fcmTokens,
    'recentMatches': recentMatches,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': iV,
  };
}

class Location {
  final String? type;
  final List<double>? coordinates;

  const Location({
    this.type,
    this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}

class City {
  final String? sId;
  final String? name;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? iV;

  const City({
    this.sId,
    this.name,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      sId: json['_id'],
      name: json['name'],
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'name': name,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': iV,
  };
}
