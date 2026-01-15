class GetScoreBoardModel {
  int? status;
  bool? success;
  String? message;
  List<Data>? data;

  GetScoreBoardModel({this.status, this.success, this.message, this.data});

  GetScoreBoardModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    data = (json['data'] as List?)
        ?.map((e) => Data.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'success': success,
        'message': message,
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class Data {
  String? sId;
  UserId? userId;
  BookingId? bookingId;
  String? matchDate;
  String? matchTime;
  String? courtName;
  String? clubName;
  List<Teams>? teams;
  TotalScore? totalScore;
  String? matchDuration;
  dynamic winner;
  List<Sets>? sets;
  String? createdAt;
  String? updatedAt;
  String? matchType;
  bool? matchStatus;
  int? iV;
  bool? isCompleted;

  Data({
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
    this.sets,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.isCompleted,
    this.matchType,
    this.matchStatus,
  });

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'] != null ? UserId.fromJson(json['userId']) : null;
    bookingId =
        json['bookingId'] != null ? BookingId.fromJson(json['bookingId']) : null;
    matchDate = json['matchDate'];
    matchTime = json['matchTime'];
    courtName = json['courtName'];
    clubName = json['clubName'];
    teams = (json['teams'] as List?)?.map((e) => Teams.fromJson(e)).toList();
    totalScore = json['totalScore'] != null
        ? TotalScore.fromJson(json['totalScore'])
        : null;
    matchDuration = json['matchDuration'];
    winner = json['winner'];
    sets = (json['sets'] as List?)?.map((e) => Sets.fromJson(e)).toList();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    isCompleted = json['isCompleted'];
    matchType = json['matchType'];
    matchStatus = json['matchStatus'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'userId': userId?.toJson(),
        'bookingId': bookingId?.toJson(),
        'matchDate': matchDate,
        'matchTime': matchTime,
        'courtName': courtName,
        'clubName': clubName,
        'teams': teams?.map((e) => e.toJson()).toList(),
        'totalScore': totalScore?.toJson(),
        'matchDuration': matchDuration,
        'winner': winner,
        'sets': sets?.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        '__v': iV,
        'isCompleted': isCompleted,
        'matchType': matchType,
        'matchStatus': matchStatus,
      };
}

class UserId {
  String? sId;
  String? name;
  String? lastName;
  String? playerLevel;
  String? profilePic;

  UserId({this.sId, this.name, this.lastName, this.playerLevel, this.profilePic});

  UserId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    lastName = json['lastName'];
    playerLevel = json['playerLevel'];
    profilePic = json['profilePic'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'name': name,
        'lastName': lastName,
        'playerLevel': playerLevel,
        'profilePic': profilePic,
      };
}

class BookingId {
  String? sId;
  String? userId;
  String? registerClubId;
  int? totalAmount;
  String? bookingDate;
  String? bookingStatus;
  String? bookingType;
  String? createdAt;
  String? ownerId;
  String? updatedAt;
  String? openMatchId;
  int? iV;

  BookingId({
    this.sId,
    this.userId,
    this.registerClubId,
    this.totalAmount,
    this.bookingDate,
    this.bookingStatus,
    this.bookingType,
    this.createdAt,
    this.ownerId,
    this.updatedAt,
    this.openMatchId,
    this.iV,
  });

  BookingId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    registerClubId = json['register_club_id'];
    totalAmount = json['totalAmount'];
    bookingDate = json['bookingDate'];
    bookingStatus = json['bookingStatus'];
    bookingType = json['bookingType'];
    createdAt = json['createdAt'];
    ownerId = json['ownerId'];
    updatedAt = json['updatedAt'];
    openMatchId = json['openMatchId'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'userId': userId,
        'register_club_id': registerClubId,
        'totalAmount': totalAmount,
        'bookingDate': bookingDate,
        'bookingStatus': bookingStatus,
        'bookingType': bookingType,
        'createdAt': createdAt,
        'ownerId': ownerId,
        'updatedAt': updatedAt,
        'openMatchId': openMatchId,
        '__v': iV,
      };
}

class Teams {
  String? name;
  List<Players>? players;
  int? totalWins;
  bool? isWinner;
  String? sId;

  Teams({this.name, this.players, this.totalWins, this.isWinner, this.sId});

  Teams.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    players =
        (json['players'] as List?)?.map((e) => Players.fromJson(e)).toList();
    totalWins = json['totalWins'];
    isWinner = json['isWinner'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'players': players?.map((e) => e.toJson()).toList(),
        'totalWins': totalWins,
        'isWinner': isWinner,
        '_id': sId,
      };
}

class Players {
  PlayerId? playerId;
  String? name;
  String? sId;

  Players({this.playerId, this.name, this.sId});

  Players.fromJson(Map<String, dynamic> json) {
    playerId =
        json['playerId'] != null ? PlayerId.fromJson(json['playerId']) : null;
    name = json['name'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId?.toJson(),
        'name': name,
        '_id': sId,
      };
}

class PlayerId {
  String? sId;
  String? name;
  String? lastName;
  String? profilePic;
  String? level;
  String? playerLevel;

  PlayerId({this.sId, this.name, this.lastName, this.profilePic, this.level,this.playerLevel});

  PlayerId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    lastName = json['lastName'];
    profilePic = json['profilePic'];
    level = json['level'];
    playerLevel = json['playerLevel'];
  }

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'name': name,
        'lastName': lastName,
        'profilePic': profilePic,
        'level': level,
        'playerLevel': playerLevel,
      };
}

class TotalScore {
  int? teamA;
  int? teamB;

  TotalScore({this.teamA, this.teamB});

  TotalScore.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }

  Map<String, dynamic> toJson() => {
        'teamA': teamA,
        'teamB': teamB,
      };
}

class Sets {
  int? setNumber;
  int? teamAScore;
  int? teamBScore;
  dynamic winner;
  String? sId;

  Sets({this.setNumber, this.teamAScore, this.teamBScore, this.winner, this.sId});

  Sets.fromJson(Map<String, dynamic> json) {
    setNumber = json['setNumber'];
    teamAScore = json['teamAScore'];
    teamBScore = json['teamBScore'];
    winner = json['winner'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'winner': winner,
        '_id': sId,
      };
}
