class ProfileModel {
  String? status;
  String? message;
  Response? response;
  bool? existsOpenMatchData;

  ProfileModel(
      {this.status, this.message, this.response, this.existsOpenMatchData});

  ProfileModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    response = json['response'] != null
        ? new Response.fromJson(json['response'])
        : null;
    existsOpenMatchData = json['existsOpenMatchData'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.response != null) {
      data['response'] = this.response!.toJson();
    }
    data['existsOpenMatchData'] = this.existsOpenMatchData;
    return data;
  }
}

class Response {
  String? lastName;
  String? profilePic;
  String? playerLevel;
  String? level;
  Location? location;
  int? totalMatchesPlayed;
  int? totalWins;
  int? simpleMatchCount;
  int? openMatchCount;
  int? americanMatchCount;
  int? rank;
  dynamic xpPoints;
  int? currentWinStreak;
  int? currentLoseStreak;
  List<Null>? recentMatches;
  int? winRatio;
  String? sId;
  String? countryCode;
  int? phoneNumber;
  bool? isActive;
  bool? isDeleted;
  String? role;
  Null? otp;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? email;
  String? name;
  City? city;
  List<String>? fcmTokens;
  String? dob;
  String? gender;

  Response(
      {this.lastName,
        this.profilePic,
        this.playerLevel,
        this.level,
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
        this.sId,
        this.countryCode,
        this.phoneNumber,
        this.isActive,
        this.isDeleted,
        this.role,
        this.otp,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.email,
        this.name,
        this.city,
        this.fcmTokens,
        this.dob,
        this.gender});

  Response.fromJson(Map<String, dynamic> json) {
    lastName = json['lastName'];
    profilePic = json['profilePic'];
    playerLevel = json['playerLevel'];
    level = json['level'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    totalMatchesPlayed = json['totalMatchesPlayed']?.toInt();
    totalWins = json['totalWins']?.toInt();
    simpleMatchCount = json['simpleMatchCount']?.toInt();
    openMatchCount = json['openMatchCount']?.toInt();
    americanMatchCount = json['americanMatchCount']?.toInt();
    rank = json['rank']?.toInt();
    xpPoints = json['xpPoints'];
    currentWinStreak = json['currentWinStreak']?.toInt();
    currentLoseStreak = json['currentLoseStreak']?.toInt();
    recentMatches = json['recentMatches'] != null ? [] : null;
    winRatio = json['winRatio']?.toInt();
    sId = json['_id'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber']?.toInt();
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    role = json['role'];
    otp = json['otp'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v']?.toInt();
    email = json['email'];
    name = json['name'];
    city = json['city'] != null ? new City.fromJson(json['city']) : null;
    fcmTokens = json['fcmTokens'] != null ? json['fcmTokens'].cast<String>() : null;
    dob = json['dob'];
    gender = json['gender'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lastName'] = this.lastName;
    data['profilePic'] = this.profilePic;
    data['playerLevel'] = this.playerLevel;
    data['level'] = this.level;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['totalMatchesPlayed'] = this.totalMatchesPlayed;
    data['totalWins'] = this.totalWins;
    data['simpleMatchCount'] = this.simpleMatchCount;
    data['openMatchCount'] = this.openMatchCount;
    data['americanMatchCount'] = this.americanMatchCount;
    data['rank'] = this.rank;
    data['xpPoints'] = this.xpPoints;
    data['currentWinStreak'] = this.currentWinStreak;
    data['currentLoseStreak'] = this.currentLoseStreak;
    data['recentMatches'] = this.recentMatches;
    data['winRatio'] = this.winRatio;
    data['_id'] = this.sId;
    data['countryCode'] = this.countryCode;
    data['phoneNumber'] = this.phoneNumber;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['role'] = this.role;
    data['otp'] = this.otp;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['email'] = this.email;
    data['name'] = this.name;
    if (this.city != null) {
      data['city'] = this.city!.toJson();
    }
    data['fcmTokens'] = this.fcmTokens;
    data['dob'] = this.dob;
    data['gender'] = this.gender;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class City {
  String? sId;
  String? name;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? iV;

  City(
      {this.sId,
        this.name,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.iV});

  City.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v']?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
