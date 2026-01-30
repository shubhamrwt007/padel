class BookingHistoryModel {
  bool? success;
  String? message;
  List<BookingHistoryData>? data;
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  BookingHistoryModel({
    this.success,
    this.message,
    this.data,
    this.total,
    this.page,
    this.limit,
    this.totalPages,
  });

  BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <BookingHistoryData>[];
      json['data'].forEach((v) {
        data!.add(BookingHistoryData.fromJson(v));
      });
    }
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['totalPages'] = totalPages;
    return data;
  }
}

class BookingHistoryData {
  String? sId;
  String? userId;
  RegisterClubId? registerClubId;
  int? totalAmount;
  String? bookingDate;
  String? bookingStatus;
  String? bookingType;
  List<Slot>? slot;
  String? createdAt;
  String? ownerId;
  String? matchType;
  String? updatedAt;
  bool? isOpenMatch;
  int? iV;
  int? duration;
  dynamic customerReview;
  OpenMatchId? openMatchId;
  Scoreboard? scoreboard;
  List<PlayerId>? playerIds;
  List<BookingTeamPlayer>? teamA;
  List<BookingTeamPlayer>? teamB;
  String? startTime;
  String? endTime;
  List<AlternativeCourt>? alternativeCourts;


  BookingHistoryData({
    this.sId,
    this.userId,
    this.registerClubId,
    this.totalAmount,
    this.bookingDate,
    this.bookingStatus,
    this.bookingType,
    this.slot,
    this.createdAt,
    this.ownerId,
    this.matchType,
    this.updatedAt,
    this.isOpenMatch,
    this.iV,
    this.duration,
    this.customerReview,
    this.openMatchId,
    this.scoreboard,
    this.playerIds,
    this.teamA,
    this.teamB,
    this.startTime,
    this.endTime,
    this.alternativeCourts,
  });

  BookingHistoryData.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    userId = json['userId']?.toString();
    registerClubId = json['register_club_id'] != null
        ? RegisterClubId.fromJson(json['register_club_id'])
        : null;
    totalAmount = json['totalAmount'];
    bookingDate = json['bookingDate']?.toString();
    bookingStatus = json['bookingStatus']?.toString();
    bookingType = json['bookingType']?.toString();

    if (json['slot'] != null) {
      slot = <Slot>[];
      json['slot'].forEach((v) {
        slot!.add(Slot.fromJson(v));
      });
    }

    createdAt = json['createdAt']?.toString();
    ownerId = json['ownerId']?.toString();
    matchType = json['matchType']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v'];
    duration = json['duration'];
    isOpenMatch = json['isOpenMatch'];
    customerReview = json['customerReview'];

    openMatchId = json['openMatchId'] != null
        ? OpenMatchId.fromJson(json['openMatchId'])
        : null;

    scoreboard = json['scoreboard'] != null
        ? Scoreboard.fromJson(json['scoreboard'])
        : null;

    if (json['playerIds'] != null) {
      playerIds = <PlayerId>[];
      json['playerIds'].forEach((v) {
        playerIds!.add(PlayerId.fromJson(v));
      });
    }

    if (json['teamA'] != null) {
      teamA = <BookingTeamPlayer>[];
      json['teamA'].forEach((v) {
        teamA!.add(BookingTeamPlayer.fromJson(v));
      });
    }

    if (json['teamB'] != null) {
      teamB = <BookingTeamPlayer>[];
      json['teamB'].forEach((v) {
        teamB!.add(BookingTeamPlayer.fromJson(v));
      });
    }
    if (json['alternativeCourts'] != null) {
      alternativeCourts = <AlternativeCourt>[];
      json['alternativeCourts'].forEach((v) {
        alternativeCourts!.add(AlternativeCourt.fromJson(v));
      });
    }


    startTime = json['startTime']?.toString();
    endTime = json['endTime']?.toString();

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['userId'] = userId;
    if (registerClubId != null) {
      data['register_club_id'] = registerClubId!.toJson();
    }
    data['totalAmount'] = totalAmount;
    data['bookingDate'] = bookingDate;
    data['bookingStatus'] = bookingStatus;
    data['bookingType'] = bookingType;
    if (slot != null) {
      data['slot'] = slot!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['ownerId'] = ownerId;
    data['matchType'] = matchType;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['duration'] = duration;
    data['isOpenMatch'] = isOpenMatch;
    data['customerReview'] = customerReview;

    if (openMatchId != null) {
      data['openMatchId'] = openMatchId!.toJson();
    }

    if (scoreboard != null) {
      data['scoreboard'] = scoreboard!.toJson();
    }

    if (playerIds != null) {
      data['playerIds'] = playerIds!.map((v) => v.toJson()).toList();
    }

    if (teamA != null) {
      data['teamA'] = teamA!.map((v) => v.toJson()).toList();
    }

    if (teamB != null) {
      data['teamB'] = teamB!.map((v) => v.toJson()).toList();
    }
    if (alternativeCourts != null) {
      data['alternativeCourts'] =
          alternativeCourts!.map((v) => v.toJson()).toList();
    }

    data['startTime'] = startTime;
    data['endTime'] = endTime;

    return data;
  }
}
class AlternativeCourt {
  String? courtId;
  String? courtName;
  List<String>? times;

  AlternativeCourt({this.courtId, this.courtName, this.times});

  AlternativeCourt.fromJson(Map<String, dynamic> json) {
    courtId = json['courtId']?.toString();
    courtName = json['courtName']?.toString();
    times = json['times'] != null
        ? List<String>.from(json['times'].map((e) => e.toString()))
        : [];
  }

  Map<String, dynamic> toJson() {
    return {
      'courtId': courtId,
      'courtName': courtName,
      'times': times,
    };
  }
}

// ✅ NEW Scoreboard class
class Scoreboard {
  String? sId;
  String? userId;
  String? bookingId;
  String? matchDate;
  String? matchTime;
  String? courtName;
  String? clubName;
  List<ScoreboardTeam>? teams;
  TotalScore? totalScore;
  String? matchDuration;
  String? winner;
  bool? isCompleted;
  String? openMatchId;
  List<dynamic>? sets;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Scoreboard({
    this.sId,
    this.userId,
    this.bookingId,
    this.matchDate,
    this.matchTime,
    this.courtName,
    this.clubName,
    this.teams,
    this.totalScore,
    this.matchDuration,
    this.winner,
    this.isCompleted,
    this.openMatchId,
    this.sets,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  Scoreboard.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    userId = json['userId']?.toString();
    bookingId = json['bookingId']?.toString();
    matchDate = json['matchDate']?.toString();
    matchTime = json['matchTime']?.toString();
    courtName = json['courtName']?.toString();
    clubName = json['clubName']?.toString();

    if (json['teams'] != null) {
      teams = <ScoreboardTeam>[];
      json['teams'].forEach((v) {
        teams!.add(ScoreboardTeam.fromJson(v));
      });
    }

    totalScore = json['totalScore'] != null
        ? TotalScore.fromJson(json['totalScore'])
        : null;

    matchDuration = json['matchDuration']?.toString();
    winner = json['winner']?.toString();
    isCompleted = json['isCompleted'];
    openMatchId = json['openMatchId']?.toString();
    sets = json['sets'] ?? [];
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['userId'] = userId;
    data['bookingId'] = bookingId;
    data['matchDate'] = matchDate;
    data['matchTime'] = matchTime;
    data['courtName'] = courtName;
    data['clubName'] = clubName;
    if (teams != null) {
      data['teams'] = teams!.map((v) => v.toJson()).toList();
    }
    if (totalScore != null) {
      data['totalScore'] = totalScore!.toJson();
    }
    data['matchDuration'] = matchDuration;
    data['winner'] = winner;
    data['isCompleted'] = isCompleted;
    data['openMatchId'] = openMatchId;
    data['sets'] = sets;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class ScoreboardTeam {
  String? name;
  List<ScoreboardPlayer>? players;
  int? totalWins;
  bool? isWinner;
  String? sId;

  ScoreboardTeam({
    this.name,
    this.players,
    this.totalWins,
    this.isWinner,
    this.sId,
  });

  ScoreboardTeam.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();

    if (json['players'] != null) {
      players = <ScoreboardPlayer>[];
      json['players'].forEach((v) {
        players!.add(ScoreboardPlayer.fromJson(v));
      });
    }

    totalWins = json['totalWins'];
    isWinner = json['isWinner'];
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    if (players != null) {
      data['players'] = players!.map((v) => v.toJson()).toList();
    }
    data['totalWins'] = totalWins;
    data['isWinner'] = isWinner;
    data['_id'] = sId;
    return data;
  }
}

class ScoreboardPlayer {
  PlayerId? playerId;
  String? name;
  String? sId;

  ScoreboardPlayer({this.playerId, this.name, this.sId});

  ScoreboardPlayer.fromJson(Map<String, dynamic> json) {
    playerId = json['playerId'] != null
        ? PlayerId.fromJson(json['playerId'])
        : null;
    name = json['name']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (playerId != null) {
      data['playerId'] = playerId!.toJson();
    }
    data['name'] = name;
    data['_id'] = sId;
    return data;
  }
}

class PlayerId {
  String? sId;
  String? email;
  int? phoneNumber;
  String? name;
  String? profilePic;

  PlayerId({
    this.sId,
    this.email,
    this.phoneNumber,
    this.name,
    this.profilePic,
  });

  PlayerId.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    email = json['email']?.toString();
    phoneNumber = json['phoneNumber'];
    name = json['name']?.toString();
    profilePic = json['profilePic']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['email'] = email;
    data['phoneNumber'] = phoneNumber;
    data['name'] = name;
    data['profilePic'] = profilePic;
    return data;
  }
}

class TotalScore {
  int? teamA;
  int? teamB;

  TotalScore({this.teamA, this.teamB});

  TotalScore.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['teamA'] = teamA;
    data['teamB'] = teamB;
    return data;
  }
}
class OpenMatchId {
  String? sId;
  String? clubId;
  List<Slot>? slot;
  String? matchType;
  String? skillLevel;
  List<dynamic>? skillDetails;
  String? matchDate;
  String? matchStatus;
  List<TeamPlayer>? teamA;
  List<TeamPlayer>? teamB;
  String? createdBy;
  String? gender;
  String? openMatchStatus;
  bool? status;
  bool? adminStatus;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  OpenMatchId({
    this.sId,
    this.clubId,
    this.slot,
    this.matchType,
    this.skillLevel,
    this.skillDetails,
    this.matchDate,
    this.matchStatus,
    this.teamA,
    this.teamB,
    this.createdBy,
    this.gender,
    this.status,
    this.adminStatus,
    this.isActive,
    this.isDeleted,
    this.openMatchStatus,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  OpenMatchId.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    clubId = json['clubId']?.toString();

    if (json['slot'] != null) {
      slot = <Slot>[];
      json['slot'].forEach((v) {
        slot!.add(Slot.fromJson(v));
      });
    }

    matchType = json['matchType']?.toString();
    skillLevel = json['skillLevel']?.toString();
    skillDetails = json['skillDetails'] ?? [];
    matchDate = json['matchDate']?.toString();
    matchStatus = json['matchStatus']?.toString();

    teamA = json['teamA'] != null
        ? (json['teamA'] as List)
        .map((e) => TeamPlayer.fromJson(e))
        .toList()
        : [];

    teamB = json['teamB'] != null
        ? (json['teamB'] as List)
        .map((e) => TeamPlayer.fromJson(e))
        .toList()
        : [];

    createdBy = json['createdBy']?.toString();
    gender = json['gender']?.toString();
    status = json['status'];
    adminStatus = json['adminStatus'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    openMatchStatus = json['openMatchStatus'];
    createdAt = json['createdAt']?.toString();
    updatedAt = json['updatedAt']?.toString();
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['clubId'] = clubId;
    data['slot'] = slot?.map((v) => v.toJson()).toList();
    data['matchType'] = matchType;
    data['skillLevel'] = skillLevel;
    data['skillDetails'] = skillDetails;
    data['matchDate'] = matchDate;
    data['matchStatus'] = matchStatus;
    data['teamA'] = teamA?.map((v) => v.toJson()).toList();
    data['teamB'] = teamB?.map((v) => v.toJson()).toList();
    data['createdBy'] = createdBy;
    data['gender'] = gender;
    data['status'] = status;
    data['adminStatus'] = adminStatus;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['openMatchStatus'] = openMatchStatus;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
class TeamPlayer {
  String? userId;
  String? joinedAt;
  String? sId;

  TeamPlayer({this.userId, this.joinedAt, this.sId});

  TeamPlayer.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    joinedAt = json['joinedAt']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'joinedAt': joinedAt,
      '_id': sId,
    };
  }
}


class RegisterClubId {
  String? sId;
  String? ownerId;
  String? clubName;
  int? iV;
  String? address;
  List<BusinessHours>? businessHours;
  String? city;
  int? courtCount;
  List<String>? courtImage;
  String? courtType;
  String? createdAt;
  List<String>? features;
  bool? isActive;
  bool? isDeleted;
  bool? isFeatured;
  bool? isVerified;
  Location? location;
  String? state;
  String? updatedAt;
  String? zipCode;
  String? description;

  RegisterClubId({
    this.sId,
    this.ownerId,
    this.clubName,
    this.iV,
    this.address,
    this.businessHours,
    this.city,
    this.courtCount,
    this.courtImage,
    this.courtType,
    this.createdAt,
    this.features,
    this.isActive,
    this.isDeleted,
    this.isFeatured,
    this.isVerified,
    this.location,
    this.state,
    this.updatedAt,
    this.zipCode,
    this.description,
  });

  RegisterClubId.fromJson(Map<String, dynamic> json) {
    sId = json['_id']?.toString();
    ownerId = json['ownerId']?.toString();
    clubName = json['clubName']?.toString();
    iV = json['__v'];

    // ✅ Safe conversion for address (can be List or String)
    var addr = json['address'];
    if (addr is List) {
      address = addr.join(' ');
    } else {
      address = addr?.toString();
    }

    if (json['businessHours'] != null) {
      businessHours = <BusinessHours>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(BusinessHours.fromJson(v));
      });
    }

    city = json['city']?.toString();
    courtCount = json['courtCount'];

    // ✅ Safe conversion for courtImage and features
    courtImage = json['courtImage'] != null
        ? List<String>.from(json['courtImage'].map((e) => e.toString()))
        : [];

    courtType = json['courtType']?.toString();
    createdAt = json['createdAt']?.toString();

    features = json['features'] != null
        ? List<String>.from(json['features'].map((e) => e.toString()))
        : [];

    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isFeatured = json['isFeatured'];
    isVerified = json['isVerified'];

    location =
    json['location'] != null ? Location.fromJson(json['location']) : null;

    state = json['state']?.toString();
    updatedAt = json['updatedAt']?.toString();
    zipCode = json['zipCode']?.toString();
    description = json['description']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = sId;
    data['ownerId'] = ownerId;
    data['clubName'] = clubName;
    data['__v'] = iV;
    data['address'] = address;
    if (businessHours != null) {
      data['businessHours'] = businessHours!.map((v) => v.toJson()).toList();
    }
    data['city'] = city;
    data['courtCount'] = courtCount;
    data['courtImage'] = courtImage;
    data['courtType'] = courtType;
    data['createdAt'] = createdAt;
    data['features'] = features;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['isFeatured'] = isFeatured;
    data['isVerified'] = isVerified;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['state'] = state;
    data['updatedAt'] = updatedAt;
    data['zipCode'] = zipCode;
    data['description'] = description;
    return data;
  }
}

class BusinessHours {
  String? time;
  String? day;
  String? sId;

  BusinessHours({this.time, this.day, this.sId});

  BusinessHours.fromJson(Map<String, dynamic> json) {
    time = json['time']?.toString();
    day = json['day']?.toString();
    sId = json['_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['time'] = time;
    data['day'] = day;
    data['_id'] = sId;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    if (json['coordinates'] != null) {
      coordinates = List<double>.from(
        json['coordinates'].map((e) => double.tryParse(e.toString()) ?? 0.0),
      );
    } else {
      coordinates = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }
}

class Slot {
  String? slotId;
  String? courtName;
  String? courtId;
  String? bookingDate;
  List<SlotTimes>? slotTimes;
  List<BusinessHours>? businessHours;

  Slot({
    this.slotId,
    this.courtName,
    this.courtId,
    this.bookingDate,
    this.slotTimes,
    this.businessHours,
  });

  Slot.fromJson(Map<String, dynamic> json) {
    slotId = json['slotId']?.toString();
    courtName = json['courtName']?.toString();
    courtId = json['courtId']?.toString();
    bookingDate = json['bookingDate']?.toString();

    if (json['slotTimes'] != null) {
      slotTimes = <SlotTimes>[];
      json['slotTimes'].forEach((v) {
        slotTimes!.add(SlotTimes.fromJson(v));
      });
    }

    if (json['businessHours'] != null) {
      businessHours = <BusinessHours>[];
      json['businessHours'].forEach((v) {
        businessHours!.add(BusinessHours.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['slotId'] = slotId;
    data['courtName'] = courtName;
    data['courtId'] = courtId;
    data['bookingDate'] = bookingDate;
    if (slotTimes != null) {
      data['slotTimes'] = slotTimes!.map((v) => v.toJson()).toList();
    }
    if (businessHours != null) {
      data['businessHours'] = businessHours!.map((v) => v.toJson()).toList();
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
    time = json['time']?.toString();
    amount = json['amount'];
    status = json['status']?.toString();
    availabilityStatus = json['availabilityStatus']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['time'] = time;
    data['amount'] = amount;
    data['status'] = status;
    data['availabilityStatus'] = availabilityStatus;
    return data;
  }
}

class BookingTeamPlayer {
  PlayerId? userId;
  dynamic amountPaid;
  String? joinedAt;
  String? sId;

  BookingTeamPlayer({this.userId, this.joinedAt, this.sId,this.amountPaid});

  BookingTeamPlayer.fromJson(Map<String, dynamic> json) {
    userId = json['userId'] != null ? PlayerId.fromJson(json['userId']) : null;
    joinedAt = json['joinedAt']?.toString();
    sId = json['_id']?.toString();
    amountPaid = json['amountPaid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (userId != null) {
      data['userId'] = userId!.toJson();
    }
    data['joinedAt'] = joinedAt;
    data['_id'] = sId;
    data['amountPaid'] = amountPaid;
    return data;
  }
}