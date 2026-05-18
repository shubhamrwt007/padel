class GetLeagueLeaderBoardModel {
  final bool? success;
  final Data? data;

  GetLeagueLeaderBoardModel({this.success, this.data});

  factory GetLeagueLeaderBoardModel.fromJson(Map<String, dynamic> json) {
    return GetLeagueLeaderBoardModel(
      success: json['success'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    if (data != null) 'data': data!.toJson(),
  };
}

class Data {
  final String? leagueId;
  final List<Standings>? standings;

  Data({this.leagueId, this.standings});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      leagueId: json['leagueId'],
      standings: (json['standings'] as List?)
          ?.map((e) => Standings.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'leagueId': leagueId,
    if (standings != null)
      'standings': standings!.map((e) => e.toJson()).toList(),
  };
}

class Standings {
  final int? position;
  final String? clubId;
  final String? clubName;
  final String? clubLogo;
  final int? played;
  final int? wins;
  final int? losses;
  final int? points;
  final int? setsWon;
  final int? setsLost;
  final int? setDifference;
  final int? previousPosition;
  final int? positionChange;
  final Map<String, dynamic>? categoryWins;
  final List<String>? recentForm;

  Standings({
    this.position,
    this.clubId,
    this.clubName,
    this.clubLogo,
    this.played,
    this.wins,
    this.losses,
    this.points,
    this.setsWon,
    this.setsLost,
    this.setDifference,
    this.previousPosition,
    this.positionChange,
    this.categoryWins,
    this.recentForm,
  });

  factory Standings.fromJson(Map<String, dynamic> json) {
    return Standings(
      position: json['position'],
      clubId: json['clubId'],
      clubName: json['clubName'],
      clubLogo: json['clubLogo'],
      played: json['played'],
      wins: json['wins'],
      losses: json['losses'],
      points: json['points'],
      setsWon: json['setsWon'],
      setsLost: json['setsLost'],
      setDifference: json['setDifference'],
      previousPosition: json['previousPosition'],
      positionChange: json['positionChange'],
      categoryWins: json['categoryWins'] as Map<String, dynamic>?,
      recentForm: (json['recentForm'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position,
    'clubId': clubId,
    'clubName': clubName,
    'clubLogo': clubLogo,
    'played': played,
    'wins': wins,
    'losses': losses,
    'points': points,
    'setsWon': setsWon,
    'setsLost': setsLost,
    'setDifference': setDifference,
    'previousPosition': previousPosition,
    'positionChange': positionChange,
    'categoryWins': categoryWins,
    'recentForm': recentForm,
  };
}