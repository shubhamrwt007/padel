class GetAllScheduleUpcomingMatchesModel {
  bool? success;
  List<Data>? data;
  Pagination? pagination;

  GetAllScheduleUpcomingMatchesModel({
    this.success,
    this.data,
    this.pagination,
  });

  factory GetAllScheduleUpcomingMatchesModel.fromJson(Map<String, dynamic> json) {
    return GetAllScheduleUpcomingMatchesModel(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => Data.fromJson(e))
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

class Data {
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

  Data({
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
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['_id'],
      leagueId:
      json['leagueId'] != null ? LeagueId.fromJson(json['leagueId']) : null,
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
    );
  }

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
  Score? score;
  int? matchNo;
  String? time;
  String? startTime;
  String? endTime;
  int? duration;
  String? status;
  String? id;

  Matches({
    this.teamA,
    this.teamB,
    this.score,
    this.matchNo,
    this.time,
    this.startTime,
    this.endTime,
    this.duration,
    this.status,
    this.id,
  });

  factory Matches.fromJson(Map<String, dynamic> json) => Matches(
    teamA: json['teamA'] != null ? Team.fromJson(json['teamA']) : null,
    teamB: json['teamB'] != null ? Team.fromJson(json['teamB']) : null,
    score: json['score'] != null ? Score.fromJson(json['score']) : null,
    matchNo: json['matchNo'],
    time: json['time'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    duration: json['duration'],
    status: json['status'],
    id: json['_id'],
  );

  Map<String, dynamic> toJson() => {
    'teamA': teamA?.toJson(),
    'teamB': teamB?.toJson(),
    'score': score?.toJson(),
    'matchNo': matchNo,
    'time': time,
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'status': status,
    '_id': id,
  };
}

class Team {
  VenueClubId? clubId;
  String? clubType;
  String? teamName;
  List<Players>? players;

  Team({this.clubId, this.clubType, this.teamName, this.players});

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    clubId:
    json['clubId'] != null ? VenueClubId.fromJson(json['clubId']) : null,
    clubType: json['clubType'],
    teamName: json['teamName'],
    players: (json['players'] as List?)
        ?.map((e) => Players.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'clubId': clubId?.toJson(),
    'clubType': clubType,
    'teamName': teamName,
    'players': players?.map((e) => e.toJson()).toList(),
  };
}

class Players {
  String? playerId;
  String? playerName;
  String? id;

  Players({this.playerId, this.playerName, this.id});

  factory Players.fromJson(Map<String, dynamic> json) => Players(
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
  int? teamA;
  int? teamB;

  Score({this.teamA, this.teamB});

  factory Score.fromJson(Map<String, dynamic> json) => Score(
    teamA: json['teamA'],
    teamB: json['teamB'],
  );

  Map<String, dynamic> toJson() => {
    'teamA': teamA,
    'teamB': teamB,
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