class AddPlayerToOpenMatchModel {
  String? message;
  Match? match;

  AddPlayerToOpenMatchModel({this.message, this.match});

  AddPlayerToOpenMatchModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    match = json['match'] != null ? Match.fromJson(json['match']) : null;
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    if (match != null) 'match': match!.toJson(),
  };
}

class Match {
  String? id;
  String? clubId;
  List<Slot>? slot;
  String? matchType;
  String? skillLevel;
  List<String>? skillDetails;
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

  Match({
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

  Match.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    clubId = json['clubId'];
    slot = (json['slot'] as List?)?.map((e) => Slot.fromJson(e)).toList();
    matchType = json['matchType'];
    skillLevel = json['skillLevel'];
    skillDetails = (json['skillDetails'] as List?)?.cast<String>();
    matchDate = json['matchDate'];
    matchTime = (json['matchTime'] as List?)?.cast<String>();
    matchStatus = json['matchStatus'];
    teamA = (json['teamA'] as List?)?.map((e) => TeamA.fromJson(e)).toList();
    teamB = (json['teamB'] as List?)?.map((e) => TeamB.fromJson(e)).toList();
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

  Map<String, dynamic> toJson() => {
    '_id': id,
    'clubId': clubId,
    if (slot != null) 'slot': slot!.map((e) => e.toJson()).toList(),
    'matchType': matchType,
    'skillLevel': skillLevel,
    'skillDetails': skillDetails,
    'matchDate': matchDate,
    'matchTime': matchTime,
    'matchStatus': matchStatus,
    if (teamA != null) 'teamA': teamA!.map((e) => e.toJson()).toList(),
    if (teamB != null) 'teamB': teamB!.map((e) => e.toJson()).toList(),
    'createdBy': createdBy,
    'gender': gender,
    'status': status,
    'adminStatus': adminStatus,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class Slot {
  String? slotId;
  String? courtName;
  List<SlotTimes>? slotTimes;

  Slot({this.slotId, this.courtName, this.slotTimes});

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = json['courtName'];
    slotTimes =
        (json['slotTimes'] as List?)?.map((e) => SlotTimes.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'courtName': courtName,
    if (slotTimes != null)
      'slotTimes': slotTimes!.map((e) => e.toJson()).toList(),
  };
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

  Map<String, dynamic> toJson() => {
    'time': time,
    'amount': amount,
    'status': status,
    'availabilityStatus': availabilityStatus,
  };
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

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'joinedAt': joinedAt,
    '_id': id,
  };
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

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'joinedAt': joinedAt,
    '_id': id,
  };
}
