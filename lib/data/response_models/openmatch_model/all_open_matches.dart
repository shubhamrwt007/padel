class AllOpenMatches {
  String? message;
  List<MatchData>? data;

  AllOpenMatches({this.message, this.data});

  AllOpenMatches.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <MatchData>[];
      json['data'].forEach((v) {
        data!.add(MatchData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class MatchData {
  String? sId;
  ClubId? clubId;
  List<Slot>? slot;
  String? matchType;
  String? skillLevel;
  List<String>? skillDetails;
  String? matchDate;
  String? matchTime;
  String? matchStatus;
  List<TeamA>? teamA;
  List<TeamB>? teamB;
  String? createdBy;
  String? gender;
  bool? status;
  bool? adminStatus;
  bool? isActive;
  bool? isDeleted;
  bool? isRequest;
  String? createdAt;
  String? updatedAt;
  int? iV;
  int? pendingRequestsCount;
  BookingId? bookingId;

  MatchData({
    this.sId,
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
    this.isRequest,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.pendingRequestsCount,
    this.bookingId,
  });

  static String? _asJoinedString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      final parts = value
          .where((element) => element != null)
          .map((element) => element.toString())
          .where((element) => element.trim().isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    }
    return value.toString();
  }

  MatchData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubId = json['clubId'] != null ? ClubId.fromJson(json['clubId']) : null;
    if (json['slot'] != null) {
      slot = <Slot>[];
      json['slot'].forEach((v) {
        slot!.add(Slot.fromJson(v));
      });
    }
    matchType = _asJoinedString(json['matchType']);
    skillLevel = _asJoinedString(json['skillLevel']);
    skillDetails = json['skillDetails']?.cast<String>();
    matchDate = _asJoinedString(json['matchDate']);
    matchTime = _asJoinedString(json['matchTime']);
    matchStatus = _asJoinedString(json['matchStatus']);
    if (json['teamA'] != null) {
      teamA = <TeamA>[];
      json['teamA'].forEach((v) {
        teamA!.add(TeamA.fromJson(v));
      });
    }
    if (json['teamB'] != null) {
      teamB = <TeamB>[];
      json['teamB'].forEach((v) {
        teamB!.add(TeamB.fromJson(v));
      });
    }
    createdBy = _asJoinedString(json['createdBy']);
    gender = _asJoinedString(json['gender']);
    status = json['status'];
    adminStatus = json['adminStatus'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isRequest = json['isRequest'];
    bookingId = json['bookingId'] != null
        ? BookingId.fromJson(json['bookingId'])
        : null;
    createdAt = _asJoinedString(json['createdAt']);
    updatedAt = _asJoinedString(json['updatedAt']);
    iV = json['__v'];
    pendingRequestsCount = json['pendingRequestsCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    if (clubId != null) {
      map['clubId'] = clubId!.toJson();
    }
    if (slot != null) {
      map['slot'] = slot!.map((v) => v.toJson()).toList();
    }
    map['matchType'] = matchType;
    map['skillLevel'] = skillLevel;
    map['skillDetails'] = skillDetails;
    map['matchDate'] = matchDate;
    map['matchTime'] = matchTime;
    map['matchStatus'] = matchStatus;
    map['isRequest'] = isRequest;
    map['bookingId'] = bookingId?.toJson();
    if (teamA != null) {
      map['teamA'] = teamA!.map((v) => v.toJson()).toList();
    }
    if (teamB != null) {
      map['teamB'] = teamB!.map((v) => v.toJson()).toList();
    }
    map['createdBy'] = createdBy;
    map['gender'] = gender;
    map['status'] = status;
    map['adminStatus'] = adminStatus;
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = iV;
    map['pendingRequestsCount'] = pendingRequestsCount;
    return map;
  }
}
class BookingId {
  String? sId;
  String? userId;
  String? registerClubId;
  int? totalAmount;
  String? bookingDate;
  String? bookingStatus;
  String? bookingType;
  String? bookingTime;
  String? matchType;
  String? paymentMethod;
  String? paymentStatus;
  String? startTime;
  String? endTime;

  BookingId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    registerClubId = json['register_club_id'];
    totalAmount = json['totalAmount'];
    bookingDate = json['bookingDate'];
    bookingStatus = json['bookingStatus'];
    bookingType = json['bookingType'];
    bookingTime = json['bookingTime'];
    matchType = json['matchType'];
    paymentMethod = json['paymentMethod'];
    paymentStatus = json['paymentStatus'];
    startTime = json['startTime'];
    endTime = json['endTime'];
  }

  Map<String, dynamic> toJson() => {
    '_id': sId,
    'userId': userId,
    'register_club_id': registerClubId,
    'totalAmount': totalAmount,
    'bookingDate': bookingDate,
    'bookingStatus': bookingStatus,
    'bookingType': bookingType,
    'bookingTime': bookingTime,
    'matchType': matchType,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class ClubId {
  String? sId;
  String? clubName;
  String? address;
  String? city;
  String? zipCode;

  ClubId({this.sId, this.clubName, this.address,this.city,this.zipCode});

  ClubId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubName = MatchData._asJoinedString(json['clubName']);
    address = MatchData._asJoinedString(json['address']);
    city = MatchData._asJoinedString(json['city']);
    zipCode = MatchData._asJoinedString(json['zipCode']);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'clubName': clubName,
      'address': address,
      'city': city,
      'zipCode': zipCode,
    };
  }
}

class Slot {
  String? slotId;
  String? courtName;
  List<SlotTimes>? slotTimes;

  Slot({this.slotId, this.courtName, this.slotTimes});

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId'];
    courtName = MatchData._asJoinedString(json['courtName']);
    if (json['slotTimes'] != null) {
      slotTimes = <SlotTimes>[];
      json['slotTimes'].forEach((v) {
        slotTimes!.add(SlotTimes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['slotId'] = slotId;
    map['courtName'] = courtName;
    if (slotTimes != null) {
      map['slotTimes'] = slotTimes!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class SlotTimes {
  String? time;
  int? amount;
  String? status;
  String? availabilityStatus;

  SlotTimes({this.time, this.amount, this.status, this.availabilityStatus});

  SlotTimes.fromJson(Map<String, dynamic> json) {
    time = MatchData._asJoinedString(json['time']);
    amount = json['amount'];
    status = MatchData._asJoinedString(json['status']);
    availabilityStatus = MatchData._asJoinedString(json['availabilityStatus']);
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'amount': amount,
      'status': status,
      'availabilityStatus': availabilityStatus,
    };
  }
}

class TeamA {
  UserId? userId;
  String? joinedAt;
  String? sId;
  bool? isTemp;
  String? name;
  String? tempPlayerId;

  TeamA({this.userId, this.joinedAt, this.sId, this.isTemp, this.name, this.tempPlayerId});

  TeamA.fromJson(Map<String, dynamic> json) {
    userId = json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    joinedAt = MatchData._asJoinedString(json['joinedAt']);
    sId = json['_id'];
    isTemp = json['isTemp'];
    name = json['name'];
    tempPlayerId = json['tempPlayerId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (userId != null) {
      map['userId'] = userId!.toJson();
    }
    map['joinedAt'] = joinedAt;
    map['_id'] = sId;
    map['isTemp'] = isTemp;
    map['name'] = name;
    map['tempPlayerId'] = tempPlayerId;
    return map;
  }
}

class TeamB {
  UserId? userId;
  String? joinedAt;
  String? sId;
  bool? isTemp;
  String? name;
  String? tempPlayerId;

  TeamB({this.userId, this.joinedAt, this.sId, this.isTemp, this.name, this.tempPlayerId});

  TeamB.fromJson(Map<String, dynamic> json) {
    userId = json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    joinedAt = MatchData._asJoinedString(json['joinedAt']);
    sId = json['_id'];
    isTemp = json['isTemp'];
    name = json['name'];
    tempPlayerId = json['tempPlayerId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (userId != null) {
      map['userId'] = userId!.toJson();
    }
    map['joinedAt'] = joinedAt;
    map['_id'] = sId;
    map['isTemp'] = isTemp;
    map['name'] = name;
    map['tempPlayerId'] = tempPlayerId;
    return map;
  }
}

class UserId {
  Location? location;
  String? sId;
  String? email;
  String? countryCode;
  int? phoneNumber;
  String? name;
  String? lastName;
  String? category;
  bool? isActive;
  bool? isDeleted;
  String? role;
  String? createdAt;
  String? updatedAt;
  int? iV;
  dynamic? xpPoints;
  String? dob;
  String? gender;
  String? profilePic;
  String? playerLevel;

  UserId({
    this.location,
    this.sId,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.category,
    this.isActive,
    this.isDeleted,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.xpPoints,
    this.dob,
    this.gender,
    this.profilePic,
    this.playerLevel,
  });

  UserId.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    sId = json['_id'];
    email = MatchData._asJoinedString(json['email']);
    countryCode = MatchData._asJoinedString(json['countryCode']);
    phoneNumber = json['phoneNumber'];
    name = MatchData._asJoinedString(json['name']);
    lastName = MatchData._asJoinedString(json['lastName']);
    category = MatchData._asJoinedString(json['category']);
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    role = MatchData._asJoinedString(json['role']);
    createdAt = MatchData._asJoinedString(json['createdAt']);
    updatedAt = MatchData._asJoinedString(json['updatedAt']);
    iV = json['__v'];
    xpPoints = json['xpPoints'];
    dob = MatchData._asJoinedString(json['dob']);
    gender = MatchData._asJoinedString(json['gender']);
    profilePic = MatchData._asJoinedString(json['profilePic']);
    playerLevel = MatchData._asJoinedString(json['playerLevel']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (location != null) {
      map['location'] = location!.toJson();
    }
    map['_id'] = sId;
    map['email'] = email;
    map['countryCode'] = countryCode;
    map['phoneNumber'] = phoneNumber;
    map['name'] = name;
    map['lastName'] = lastName;
    map['category'] = category;
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    map['role'] = role;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = iV;
    map['xpPoints'] = xpPoints;
    map['dob'] = dob;
    map['gender'] = gender;
    map['profilePic'] = profilePic;
    map['playerLevel'] = playerLevel;
    return map;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = MatchData._asJoinedString(json['type']);
    coordinates = json['coordinates']?.cast<double>();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}
