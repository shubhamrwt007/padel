class PushOpenMatchInScoreBoardModel {
  final bool? success;
  final String? message;
  final MatchData? data;

  PushOpenMatchInScoreBoardModel({
    this.success,
    this.message,
    this.data,
  });

  factory PushOpenMatchInScoreBoardModel.fromJson(Map<String, dynamic> json) {
    return PushOpenMatchInScoreBoardModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] == null ? null : MatchData.fromJson(json['data']),
    );
  }
}

class MatchData {
  final TotalScore? totalScore;
  final String? id;
  final String? userId;
  final String? bookingId;
  final String? matchDate;
  final String? matchTime;
  final String? courtName;
  final String? clubName;
  final List<Team> teams;
  final String? matchDuration;
  final String? winner;
  final bool? isCompleted;
  final String? matchType;
  final bool? matchStatus;
  final List<dynamic> sets;
  final String? createdAt;
  final String? updatedAt;
  final int? version;
  final String? openMatchId;

  MatchData({
    this.totalScore,
    this.id,
    this.userId,
    this.bookingId,
    this.matchDate,
    this.matchTime,
    this.courtName,
    this.clubName,
    required this.teams,
    this.matchDuration,
    this.winner,
    this.isCompleted,
    this.matchType,
    this.matchStatus,
    required this.sets,
    this.createdAt,
    this.updatedAt,
    this.version,
    this.openMatchId,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      totalScore: json['totalScore'] == null
          ? null
          : TotalScore.fromJson(json['totalScore']),
      id: json['_id'],
      userId: json['userId'],
      bookingId: json['bookingId'],
      matchDate: json['matchDate'],
      matchTime: json['matchTime'],
      courtName: json['courtName'],
      clubName: json['clubName'],
      teams: (json['teams'] as List? ?? [])
          .map((e) => Team.fromJson(e))
          .toList(),
      matchDuration: json['matchDuration'],
      winner: json['winner'],
      isCompleted: json['isCompleted'],
      matchType: json['matchType'],
      matchStatus: json['matchStatus'],
      sets: json['sets'] ?? [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      version: json['__v'],
      openMatchId: json['openMatchId'],
    );
  }
}

class TotalScore {
  final int? teamA;
  final int? teamB;

  TotalScore({this.teamA, this.teamB});

  factory TotalScore.fromJson(Map<String, dynamic> json) {
    return TotalScore(
      teamA: json['teamA'],
      teamB: json['teamB'],
    );
  }
}

class Team {
  final String? id;
  final String? name;
  final List<Player> players;
  final int? totalWins;
  final bool? isWinner;

  Team({
    this.id,
    this.name,
    required this.players,
    this.totalWins,
    this.isWinner,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'],
      name: json['name'],
      players: (json['players'] as List? ?? [])
          .map((e) => Player.fromJson(e))
          .toList(),
      totalWins: json['totalWins'],
      isWinner: json['isWinner'],
    );
  }
}

class Player {
  final String? id;
  final String? playerId;
  final String? name;

  Player({this.id, this.playerId, this.name});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id'],
      playerId: json['playerId'],
      name: json['name'],
    );
  }
}
