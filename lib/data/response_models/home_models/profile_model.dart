class ProfileModel {
  String? status;
  String? message;
  Response? response;
  bool? existsOpenMatchData;

  ProfileModel({
    this.status,
    this.message,
    this.response,
    this.existsOpenMatchData,
  });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    response = json['response'] != null
        ? Response.fromJson(json['response'])
        : null;
    existsOpenMatchData = json['existsOpenMatchData'];
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'response': response?.toJson(),
      'existsOpenMatchData': existsOpenMatchData,
    };
  }
}

class Response {
  Location? location;
  String? sId;
  String? email;
  String? countryCode;
  int? phoneNumber;
  String? name;
  String? lastName;
  String? password;
  String? city;
  bool? agreeTermsAndCondition;
  String? category;
  bool? isActive;
  bool? isDeleted;
  String? role;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? dob;
  String? gender;
  String? profilePic;
  String? playerLevel;
  String? level;

  int? currentLoseStreak;
  int? currentWinStreak;
  dynamic? xpPoints;

  int? americanMatchCount;
  int? openMatchCount;
  int? rank;
  int? simpleMatchCount;
  int? totalMatchesPlayed;
  int? totalWins;
  List<String>? recentMatches;


  Response({
    this.location,
    this.sId,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.password,
    this.city,
    this.agreeTermsAndCondition,
    this.category,
    this.isActive,
    this.isDeleted,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.dob,
    this.gender,
    this.profilePic,
    this.playerLevel,
    this.level,
    this.currentLoseStreak,
    this.currentWinStreak,
    this.xpPoints,
    this.americanMatchCount,
    this.openMatchCount,
    this.rank,
    this.simpleMatchCount,
    this.totalMatchesPlayed,
    this.totalWins,
    this.recentMatches,
  });

  Response.fromJson(Map<String, dynamic> json) {
    location =
    json['location'] != null ? Location.fromJson(json['location']) : null;
    sId = json['_id'];
    email = json['email'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    name = json['name'];
    lastName = json['lastName'];
    password = json['password'];
    city = json['city'];
    agreeTermsAndCondition = json['agreeTermsAndCondition'];
    category = json['category'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    role = json['role'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    dob = json['dob'];
    gender = json['gender'];
    profilePic = json['profilePic'];
    playerLevel = json['playerLevel'];
    level = json['level'];

    currentLoseStreak = json['currentLoseStreak'];
    currentWinStreak = json['currentWinStreak'];
    xpPoints = (json['xpPoints'] as num?)?.toDouble();

    americanMatchCount = json['americanMatchCount'];
    openMatchCount = json['openMatchCount'];
    rank = json['rank'];
    simpleMatchCount = json['simpleMatchCount'];
    totalMatchesPlayed = json['totalMatchesPlayed'];
    totalWins = json['totalWins'];
    recentMatches = json['recentMatches'] != null
        ? List<String>.from(json['recentMatches'])
        : null;

  }

  Map<String, dynamic> toJson() {
    return {
      'location': location?.toJson(),
      '_id': sId,
      'email': email,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'name': name,
      'lastName': lastName,
      'password': password,
      'city': city,
      'agreeTermsAndCondition': agreeTermsAndCondition,
      'category': category,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
      'dob': dob,
      'gender': gender,
      'profilePic': profilePic,
      'playerLevel': playerLevel,
      'level': level,
      'currentLoseStreak': currentLoseStreak,
      'currentWinStreak': currentWinStreak,
      'xpPoints': xpPoints,
      'americanMatchCount': americanMatchCount,
      'openMatchCount': openMatchCount,
      'rank': rank,
      'simpleMatchCount': simpleMatchCount,
      'totalMatchesPlayed': totalMatchesPlayed,
      'totalWins': totalWins,
      'recentMatches': recentMatches,

    };
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];

    // Safe conversion to List<double>
    if (json['coordinates'] != null) {
      coordinates = List<double>.from(
        json['coordinates'].map((x) => (x as num).toDouble()),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}