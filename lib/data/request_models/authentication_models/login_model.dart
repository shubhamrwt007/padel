class LoginModel {
  String? status;
  String? message;
  LoginResponse? response;

  LoginModel({this.status, this.message, this.response});

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      status: json['status']?.toString(),
      message: json['message'],
      response: json['response'] != null
          ? LoginResponse.fromJson(json['response'])
          : null,
    );
  }
}

// --------------------------------------------------

class LoginResponse {
  String? token;
  User? user;

  LoginResponse({this.token, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

// --------------------------------------------------

class User {
  Location? location;

  int? totalMatchesPlayed;
  int? totalWins;
  int? simpleMatchCount;
  int? openMatchCount;
  int? americanMatchCount;
  int? rank;
  int? xpPoints;
  int? currentWinStreak;
  int? currentLoseStreak;
  List<dynamic>? recentMatches;
  int? winRatio;

  String? id;
  String? countryCode;
  int? phoneNumber;
  bool? isActive;
  bool? isDeleted;
  String? role;
  dynamic otp;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<String>? fcmTokens;

  User({
    this.location,
    this.totalMatchesPlayed,
    this.totalWins,
    this.simpleMatchCount,
    this.openMatchCount,
    this.americanMatchCount,
    this.rank,
    this.xpPoints,
    this.currentWinStreak,
    this.currentLoseStreak,
    this.recentMatches,
    this.winRatio,
    this.id,
    this.countryCode,
    this.phoneNumber,
    this.isActive,
    this.isDeleted,
    this.role,
    this.otp,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.fcmTokens,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,

      totalMatchesPlayed: json['totalMatchesPlayed'],
      totalWins: json['totalWins'],
      simpleMatchCount: json['simpleMatchCount'],
      openMatchCount: json['openMatchCount'],
      americanMatchCount: json['americanMatchCount'],
      rank: json['rank'],
      xpPoints: json['xpPoints'],
      currentWinStreak: json['currentWinStreak'],
      currentLoseStreak: json['currentLoseStreak'],
      recentMatches: json['recentMatches'] ?? [],
      winRatio: json['winRatio'],

      id: json['_id'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      role: json['role'],
      otp: json['otp'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      iV: json['__v'],
      fcmTokens: json['fcmTokens'] != null
          ? List<String>.from(json['fcmTokens'])
          : [],
    );
  }
}

// --------------------------------------------------

class Location {
  List<double>? coordinates;

  Location({this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      coordinates: json['coordinates'] != null
          ? (json['coordinates'] as List)
          .map((e) => (e as num).toDouble())
          .toList()
          : [],
    );
  }
}
