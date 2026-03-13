class GetAllScheduleLiveMatchesModel {
  bool? success;
  List<ScheduleMatchData>? data;
  Pagination? pagination;

  GetAllScheduleLiveMatchesModel({this.success, this.data, this.pagination});

  factory GetAllScheduleLiveMatchesModel.fromJson(Map<String, dynamic> json) {
    return GetAllScheduleLiveMatchesModel(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => ScheduleMatchData.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data?.map((e) => e.toJson()).toList(),
    'pagination': pagination?.toJson(),
  };
}

class ScheduleMatchData {
  String? id;
  LeagueId? leagueId;
  String? categoryType;
  VenueClubId? venueClubId;
  String? date;
  String? venue;
  String? roundType;
  List<Matches>? matches;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? matchStatus;
  String? matchId;

  ScheduleMatchData({
    this.id,
    this.leagueId,
    this.categoryType,
    this.venueClubId,
    this.date,
    this.venue,
    this.roundType,
    this.matches,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.matchStatus,
    this.matchId,
  });

  factory ScheduleMatchData.fromJson(Map<String, dynamic> json) => ScheduleMatchData(
    id: json['_id'],
    leagueId: json['leagueId'] != null
        ? LeagueId.fromJson(json['leagueId'])
        : null,
    categoryType: json['categoryType'],
    venueClubId: json['venueClubId'] != null
        ? VenueClubId.fromJson(json['venueClubId'])
        : null,
    date: json['date'],
    venue: json['venue'],
    roundType: json['roundType'],
    matches: (json['matches'] as List?)
        ?.map((e) => Matches.fromJson(e))
        .toList(),
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    v: json['__v'],
    matchStatus: json['matchStatus'],
    matchId: json['matchId'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'leagueId': leagueId?.toJson(),
    'categoryType': categoryType,
    'venueClubId': venueClubId?.toJson(),
    'date': date,
    'venue': venue,
    'roundType': roundType,
    'matches': matches?.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
    'matchStatus': matchStatus,
    'matchId': matchId,
  };
}

class LeagueId {
  String? id;
  String? leagueName;

  LeagueId({this.id, this.leagueName});

  factory LeagueId.fromJson(Map<String, dynamic> json) => LeagueId(
    id: json['_id'],
    leagueName: json['leagueName'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'leagueName': leagueName,
  };
}

class VenueClubId {
  String? id;
  String? clubName;

  VenueClubId({this.id, this.clubName});

  factory VenueClubId.fromJson(Map<String, dynamic> json) => VenueClubId(
    id: json['_id'],
    clubName: json['clubName'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'clubName': clubName,
  };
}

class Matches {
  Team? teamA;
  Team? teamB;
  int? matchNo;
  String? time;
  String? startTime;
  String? endTime;
  int? duration;
  String? status;
  Score? score;
  String? id;
  String? winner;
  Team? winningTeam;
  Team? losingTeam;

  Matches({
    this.teamA,
    this.teamB,
    this.matchNo,
    this.time,
    this.startTime,
    this.endTime,
    this.duration,
    this.status,
    this.score,
    this.id,
    this.winner,
    this.winningTeam,
    this.losingTeam,
  });

  factory Matches.fromJson(Map<String, dynamic> json) => Matches(
    teamA: json['teamA'] != null ? Team.fromJson(json['teamA']) : null,
    teamB: json['teamB'] != null ? Team.fromJson(json['teamB']) : null,
    matchNo: json['matchNo'],
    time: json['time'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    duration: json['duration'],
    status: json['status'],
    score: json['score'] != null ? Score.fromJson(json['score']) : null,
    id: json['_id'],
    winner: json['winner'],
    winningTeam: json['winningTeam'] != null ? Team.fromJson(json['winningTeam']) : null,
    losingTeam: json['losingTeam'] != null ? Team.fromJson(json['losingTeam']) : null,
  );

  Map<String, dynamic> toJson() => {
    'teamA': teamA?.toJson(),
    'teamB': teamB?.toJson(),
    'matchNo': matchNo,
    'time': time,
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'status': status,
    'score': score?.toJson(),
    '_id': id,
    'winner': winner,
    'winningTeam': winningTeam?.toJson(),
    'losingTeam': losingTeam?.toJson(),
  };
}

class Team {
  VenueClubId? clubId;
  String? clubType;
  String? teamName;
  List<Player>? players;

  Team({this.clubId, this.clubType, this.teamName, this.players});

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    clubId: json['clubId'] != null
        ? VenueClubId.fromJson(json['clubId'])
        : null,
    clubType: json['clubType'],
    teamName: json['teamName'],
    players: (json['players'] as List?)
        ?.map((e) => Player.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'clubId': clubId?.toJson(),
    'clubType': clubType,
    'teamName': teamName,
    'players': players?.map((e) => e.toJson()).toList(),
  };
}

class Player {
  String? playerId;
  String? playerName;
  String? id;

  Player({this.playerId, this.playerName, this.id});

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    playerId: json['playerId'],
    playerName: json['playerName'],
    id: json['_id'],
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    '_id': id,
  };
}

class Score {
  dynamic teamA;
  dynamic teamB;

  Score({this.teamA, this.teamB});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      teamA: json['teamA'] is Map<String, dynamic> 
          ? ScoreDetail.fromJson(json['teamA']) 
          : json['teamA'],
      teamB: json['teamB'] is Map<String, dynamic> 
          ? ScoreDetail.fromJson(json['teamB']) 
          : json['teamB'],
    );
  }

  Map<String, dynamic> toJson() => {
    'teamA': teamA is ScoreDetail ? (teamA as ScoreDetail).toJson() : teamA,
    'teamB': teamB is ScoreDetail ? (teamB as ScoreDetail).toJson() : teamB,
  };
}

class ScoreDetail {
  int? sets;
  List<int>? games;

  ScoreDetail({this.sets, this.games});

  factory ScoreDetail.fromJson(Map<String, dynamic> json) => ScoreDetail(
    sets: json['sets'],
    games: (json['games'] as List?)?.map((e) => e as int).toList(),
  );

  Map<String, dynamic> toJson() => {
    'sets': sets,
    'games': games,
  };
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination({this.total, this.page, this.limit, this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json['total'],
    page: json['page'],
    limit: json['limit'],
    totalPages: json['totalPages'],
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'page': page,
    'limit': limit,
    'totalPages': totalPages,
  };
}