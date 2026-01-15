class AcceptOrRejectRequestPlayersModel {
  String? message;
  Request? request;

  AcceptOrRejectRequestPlayersModel({this.message, this.request});

  AcceptOrRejectRequestPlayersModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    request = json['request'] != null
        ? Request.fromJson(json['request'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['message'] = message;
    if (request != null) data['request'] = request!.toJson();
    return data;
  }
}

class Request {
  String? id;
  MatchId? matchId;
  RequesterId? requesterId;
  String? matchCreatorId;
  String? preferredTeam;
  String? status;
  String? level;
  String? createdAt;
  String? updatedAt;
  int? v;

  Request({
    this.id,
    this.matchId,
    this.requesterId,
    this.matchCreatorId,
    this.preferredTeam,
    this.status,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Request.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    matchId = json['matchId'] != null
        ? MatchId.fromJson(json['matchId'])
        : null;
    requesterId = json['requesterId'] != null
        ? RequesterId.fromJson(json['requesterId'])
        : null;
    matchCreatorId = json['matchCreatorId'];
    preferredTeam = json['preferredTeam'];
    status = json['status'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['_id'] = id;
    if (matchId != null) data['matchId'] = matchId!.toJson();
    if (requesterId != null) data['requesterId'] = requesterId!.toJson();
    data['matchCreatorId'] = matchCreatorId;
    data['preferredTeam'] = preferredTeam;
    data['status'] = status;
    data['level'] = level;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = v;
    return data;
  }
}

class MatchId {
  String? id;
  String? clubId;
  List<Slot>? slot;
  String? matchType;
  String? skillLevel;
  List<dynamic>? skillDetails; // changed null type to dynamic
  String? matchDate;
  List<String>? matchTime;
  bool? matchStatus;
  List<TeamA>? teamA;
  List<TeamB>? teamB;
  String? createdBy;
  String? gender;
  bool? status;
  bool? adminStatus;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? v;

  MatchId({
    this.id,
    this.clubId,
    this.slot,
    this.matchType,
    this.skillLevel,
    this.skillDetails,
    this.matchDate,
    this.matchTime,
    this.matchStatus,
    this.teamA,
    this.teamB,
    this.createdBy,
    this.gender,
    this.status,
    this.adminStatus,
    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  MatchId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    clubId = json['clubId'];

    if (json['slot'] != null) {
      slot = List.from(json['slot'].map((e) => Slot.fromJson(e)));
    }

    matchType = json['matchType'];
    skillLevel = json['skillLevel'];

    skillDetails = json['skillDetails']?.map((e) => e).toList();

    matchDate = json['matchDate'];
    matchTime = json['matchTime']?.cast<String>();
    matchStatus = json['matchStatus'];

    if (json['teamA'] != null) {
      teamA = List.from(json['teamA'].map((e) => TeamA.fromJson(e)));
    }

    if (json['teamB'] != null) {
      teamB = List.from(json['teamB'].map((e) => TeamB.fromJson(e)));
    }

    createdBy = json['createdBy'];
    gender = json['gender'];
    status = json['status'];
    adminStatus = json['adminStatus'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['_id'] = id;
    data['clubId'] = clubId;
    if (slot != null) data['slot'] = slot!.map((e) => e.toJson()).toList();
    data['matchType'] = matchType;
    data['skillLevel'] = skillLevel;
    data['skillDetails'] = skillDetails;
    data['matchDate'] = matchDate;
    data['matchTime'] = matchTime;
    data['matchStatus'] = matchStatus;
    if (teamA != null) data['teamA'] = teamA!.map((e) => e.toJson()).toList();
    if (teamB != null) data['teamB'] = teamB!.map((e) => e.toJson()).toList();
    data['createdBy'] = createdBy;
    data['gender'] = gender;
    data['status'] = status;
    data['adminStatus'] = adminStatus;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = v;
    return data;
  }
}

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  List<SlotTimes>? slotTimes;

  Slot({this.slotId, this.courtName, this.courtId, this.slotTimes});

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = json['courtName'];
    courtId = json['courtId'];

    if (json['slotTimes'] != null) {
      slotTimes = List.from(json['slotTimes'].map((e) => SlotTimes.fromJson(e)));
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['slotId'] = slotId;
    data['courtName'] = courtName;
    data['courtId'] = courtId;
    if (slotTimes != null) {
      data['slotTimes'] = slotTimes!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class SlotTimes {
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;

  SlotTimes({this.time, this.amount, this.status, this.availabilityStatus});

  SlotTimes.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    amount = json['amount'];
    status = json['status'];
    availabilityStatus = json['availabilityStatus'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['time'] = time;
    data['amount'] = amount;
    data['status'] = status;
    data['availabilityStatus'] = availabilityStatus;
    return data;
  }
}

class TeamA {
  String? userId;
  String? joinedAt;
  String? id;

  TeamA({this.userId, this.joinedAt, this.id});

  TeamA.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    joinedAt = json['joinedAt'];
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userId'] = userId;
    data['joinedAt'] = joinedAt;
    data['_id'] = id;
    return data;
  }
}

class TeamB {
  String? userId;
  String? joinedAt;
  String? id;

  TeamB({this.userId, this.joinedAt, this.id});

  TeamB.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    joinedAt = json['joinedAt'];
    id = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['userId'] = userId;
    data['joinedAt'] = joinedAt;
    data['_id'] = id;
    return data;
  }
}

class RequesterId {
  Location? location;
  String? id;
  String? email;
  String? countryCode;
  int? phoneNumber;
  String? name;
  String? password;
  String? city;
  bool? agreeTermsAndCondition;
  String? category;
  bool? isActive;
  bool? isDeleted;
  String? role;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<String>? fcmTokens;
  String? dob;
  String? gender;
  String? profilePic;
  String? lastName;
  String? customerAge;
  String? customerRacketSport;
  String? customerScale;
  String? playerLevel;
  String? reboundSkills;
  String? receivingTP;
  String? volleyNetPositioning;

  RequesterId({
    this.location,
    this.id,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.password,
    this.city,
    this.agreeTermsAndCondition,
    this.category,
    this.isActive,
    this.isDeleted,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.fcmTokens,
    this.dob,
    this.gender,
    this.profilePic,
    this.lastName,
    this.customerAge,
    this.customerRacketSport,
    this.customerScale,
    this.playerLevel,
    this.reboundSkills,
    this.receivingTP,
    this.volleyNetPositioning,
  });

  RequesterId.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    id = json['_id'];
    email = json['email'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    name = json['name'];
    password = json['password'];
    city = json['city'];
    agreeTermsAndCondition = json['agreeTermsAndCondition'];
    category = json['category'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    role = json['role'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    fcmTokens = json['fcmTokens']?.cast<String>();
    dob = json['dob'];
    gender = json['gender'];
    profilePic = json['profilePic'];
    lastName = json['lastName'];
    customerAge = json['customerAge'];
    customerRacketSport = json['customerRacketSport'];
    customerScale = json['customerScale'];
    playerLevel = json['playerLevel'];
    reboundSkills = json['reboundSkills'];
    receivingTP = json['receivingTP'];
    volleyNetPositioning = json['volleyNetPositioning'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (location != null) data['location'] = location!.toJson();
    data['_id'] = id;
    data['email'] = email;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['name'] = name;
    data['password'] = password;
    data['city'] = city;
    data['agreeTermsAndCondition'] = agreeTermsAndCondition;
    data['category'] = category;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['role'] = role;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = v;
    data['fcmTokens'] = fcmTokens;
    data['dob'] = dob;
    data['gender'] = gender;
    data['profilePic'] = profilePic;
    data['lastName'] = lastName;
    data['customerAge'] = customerAge;
    data['customerRacketSport'] = customerRacketSport;
    data['customerScale'] = customerScale;
    data['playerLevel'] = playerLevel;
    data['reboundSkills'] = reboundSkills;
    data['receivingTP'] = receivingTP;
    data['volleyNetPositioning'] = volleyNetPositioning;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates']?.cast<double>();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }
}
