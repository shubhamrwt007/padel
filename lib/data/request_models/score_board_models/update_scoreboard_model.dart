class UpdateScoreBoardModel {
  bool? success;
  String? message;
  Data? data;

  UpdateScoreBoardModel({this.success, this.message, this.data});

  UpdateScoreBoardModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class Data {
  TotalScore? totalScore;
  String? sId;
  String? userId;
  String? bookingId;
  String? matchDate;
  String? matchTime;
  String? courtName;
  String? clubName;
  List<Teams>? teams;
  List<Sets>? sets;
  String? matchDuration;
  dynamic winner;
  String? createdAt;
  String? updatedAt;
  int? iV;
  int? xpEarned;
  int? xpLost;

  Data({
    this.totalScore,
    this.sId,
    this.userId,
    this.bookingId,
    this.matchDate,
    this.matchTime,
    this.courtName,
    this.clubName,
    this.teams,
    this.sets,
    this.matchDuration,
    this.winner,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.xpEarned,
    this.xpLost,
  });

  Data.fromJson(Map<String, dynamic> json) {
    totalScore = json['totalScore'] != null
        ? TotalScore.fromJson(json['totalScore'])
        : null;
    sId = json['_id'];
    userId = json['userId'];
    bookingId = json['bookingId'];
    matchDate = json['matchDate'];
    matchTime = json['matchTime'];
    courtName = json['courtName'];
    clubName = json['clubName'];
    teams = (json['teams'] as List?)
        ?.map((e) => Teams.fromJson(e))
        .toList();
    sets = (json['sets'] as List?)
        ?.map((e) => Sets.fromJson(e))
        .toList();
    matchDuration = json['matchDuration'];
    winner = json['winner'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    xpEarned = json['xpEarned'];
    xpLost = json['xpLost'];
  }

  Map<String, dynamic> toJson() => {
        if (totalScore != null) 'totalScore': totalScore!.toJson(),
        '_id': sId,
        'userId': userId,
        'bookingId': bookingId,
        'matchDate': matchDate,
        'matchTime': matchTime,
        'courtName': courtName,
        'clubName': clubName,
        if (teams != null) 'teams': teams!.map((e) => e.toJson()).toList(),
        if (sets != null) 'sets': sets!.map((e) => e.toJson()).toList(),
        'matchDuration': matchDuration,
        'winner': winner,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        '__v': iV,
        'xpEarned': xpEarned,
        'xpLost': xpLost,
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

class Teams {
  String? name;
  List<Players>? players;
  int? totalWins;
  bool? isWinner;
  String? sId;

  Teams({this.name, this.players, this.totalWins, this.isWinner, this.sId});

  Teams.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    players = (json['players'] as List?)
        ?.map((e) => Players.fromJson(e))
        .toList();
    totalWins = json['totalWins'];
    isWinner = json['isWinner'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (players != null)
          'players': players!.map((e) => e.toJson()).toList(),
        'totalWins': totalWins,
        'isWinner': isWinner,
        '_id': sId,
      };
}

class Players {
  String? playerId;
  String? name;
  String? sId;

  Players({this.playerId, this.name, this.sId});

  Players.fromJson(Map<String, dynamic> json) {
    playerId = json['playerId'];
    name = json['name'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        '_id': sId,
      };
}

class Sets {
  int? setNumber;
  int? teamAScore;
  int? teamBScore;
  dynamic winner;
  String? sId;

  Sets({
    this.setNumber,
    this.teamAScore,
    this.teamBScore,
    this.winner,
    this.sId,
  });

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
