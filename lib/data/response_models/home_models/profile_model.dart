class ProfileModel {
  final String? status;
  final String? message;
  final ProfileResponse? response;
  final bool? existsOpenMatchData;
  final bool? isCityNull;

  const ProfileModel({
    this.status,
    this.message,
    this.response,
    this.existsOpenMatchData,
    this.isCityNull,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileModel(
        status: json['status']?.toString(),
        message: json['message']?.toString(),
        response: json['response'] != null
            ? ProfileResponse.fromJson(json['response'] as Map<String, dynamic>)
            : null,
        existsOpenMatchData: json['existsOpenMatchData'] as bool?,
        isCityNull: json['isCityNull'] as bool?,
      );
    } catch (e) {
      print('Error parsing ProfileModel: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'response': response?.toJson(),
    'existsOpenMatchData': existsOpenMatchData,
    'isCityNull': isCityNull,
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
  final dynamic winRatio;
  final int? currentWinStreak;
  final int? currentLoseStreak;

  final dynamic xpPoints;
  final List<String>? fcmTokens;
  final List<dynamic>? recentMatches;

  // PICKLEBALL FIELDS
  final int? pickleballCurrentLoseStreak;
  final int? pickleballCurrentWinStreak;
  final int? pickleballMatchesPlayed;
  final List<dynamic>? pickleballRecentMatches;
  final int? pickleballTier;
  final String? pickleballTierLabel;
  final dynamic pickleballWinRatio;
  final int? pickleballWins;
  final dynamic pickleballXpPoints;

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

    // PICKLEBALL
    this.pickleballCurrentLoseStreak,
    this.pickleballCurrentWinStreak,
    this.pickleballMatchesPlayed,
    this.pickleballRecentMatches,
    this.pickleballTier,
    this.pickleballTierLabel,
    this.pickleballWinRatio,
    this.pickleballWins,
    this.pickleballXpPoints,

    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileResponse(
        sId: json['_id']?.toString(),
        name: json['name']?.toString(),
        lastName: json['lastName']?.toString(),
        email: json['email']?.toString(),
        profilePic: json['profilePic']?.toString(),
        playerLevel: json['playerLevel']?.toString(),
        level: json['level']?.toString(),
        role: json['role']?.toString(),
        countryCode: json['countryCode']?.toString(),
        phoneNumber: _parseIntSafely(json['phoneNumber']),
        dob: json['dob']?.toString(),
        gender: json['gender']?.toString(),

        location: json['location'] != null
            ? Location.fromJson(json['location'] as Map<String, dynamic>)
            : null,

        city: json['city'] != null
            ? City.fromJson(json['city'] as Map<String, dynamic>)
            : null,

        totalMatchesPlayed:
        _parseIntSafely(json['totalMatchesPlayed']),
        totalWins: _parseIntSafely(json['totalWins']),
        simpleMatchCount:
        _parseIntSafely(json['simpleMatchCount']),
        openMatchCount:
        _parseIntSafely(json['openMatchCount']),
        americanMatchCount:
        _parseIntSafely(json['americanMatchCount']),
        rank: _parseIntSafely(json['rank']),
        winRatio: json['winRatio'],
        currentWinStreak:
        _parseIntSafely(json['currentWinStreak']),
        currentLoseStreak:
        _parseIntSafely(json['currentLoseStreak']),

        xpPoints: json['xpPoints'],

        fcmTokens: (json['fcmTokens'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),

        recentMatches:
        json['recentMatches'] as List<dynamic>?,

        // PICKLEBALL
        pickleballCurrentLoseStreak:
        _parseIntSafely(json['pickleballCurrentLoseStreak']),

        pickleballCurrentWinStreak:
        _parseIntSafely(json['pickleballCurrentWinStreak']),

        pickleballMatchesPlayed:
        _parseIntSafely(json['pickleballMatchesPlayed']),

        pickleballRecentMatches:
        json['pickleballRecentMatches'] as List<dynamic>?,

        pickleballTier:
        _parseIntSafely(json['pickleballTier']),

        pickleballTierLabel:
        json['pickleballTierLabel']?.toString(),

        pickleballWinRatio:
        json['pickleballWinRatio'],

        pickleballWins:
        _parseIntSafely(json['pickleballWins']),

        pickleballXpPoints:
        json['pickleballXpPoints'],

        isActive: json['isActive'] as bool?,
        isDeleted: json['isDeleted'] as bool?,
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
        iV: _parseIntSafely(json['__v']),
      );
    } catch (e) {
      print('Error parsing ProfileResponse: $e');
      print('JSON: $json');
      rethrow;
    }
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

    // PICKLEBALL
    'pickleballCurrentLoseStreak':
    pickleballCurrentLoseStreak,
    'pickleballCurrentWinStreak':
    pickleballCurrentWinStreak,
    'pickleballMatchesPlayed':
    pickleballMatchesPlayed,
    'pickleballRecentMatches':
    pickleballRecentMatches,
    'pickleballTier': pickleballTier,
    'pickleballTierLabel': pickleballTierLabel,
    'pickleballWinRatio': pickleballWinRatio,
    'pickleballWins': pickleballWins,
    'pickleballXpPoints': pickleballXpPoints,

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
    try {
      return Location(
        type: json['type']?.toString(),
        coordinates: (json['coordinates'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );
    } catch (e) {
      print('Error parsing Location: $e');
      rethrow;
    }
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
    try {
      return City(
        sId: json['_id']?.toString(),
        name: json['name']?.toString(),
        isActive: json['isActive'] as bool?,
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
        iV: json['__v'] != null
            ? (json['__v'] is int ? json['__v'] as int : (json['__v'] as num).toInt())
            : null,
      );
    } catch (e) {
      print('Error parsing City: $e');
      rethrow;
    }
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