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
  final int? played;
  final int? wins;
  final int? losses;
  final int? points;
  final int? setsWon;
  final int? setsLost;
  final int? setDifference;
  final int? abWins;
  final int? cdWins;
  final int? womensWins;
  final int? mixedWins;
  final int? hybridWins;

  Standings({
    this.position,
    this.clubId,
    this.clubName,
    this.played,
    this.wins,
    this.losses,
    this.points,
    this.setsWon,
    this.setsLost,
    this.setDifference,
    this.abWins,
    this.cdWins,
    this.womensWins,
    this.mixedWins,
    this.hybridWins,
  });

  factory Standings.fromJson(Map<String, dynamic> json) {
    return Standings(
      position: json['position'],
      clubId: json['clubId'],
      clubName: json['clubName'],
      played: json['played'],
      wins: json['wins'],
      losses: json['losses'],
      points: json['points'],
      setsWon: json['setsWon'],
      setsLost: json['setsLost'],
      setDifference: json['setDifference'],
      abWins: json['abWins'],
      cdWins: json['cdWins'],
      womensWins: json['womensWins'],
      mixedWins: json['mixedWins'],
      hybridWins: json['hybridWins'],
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position,
    'clubId': clubId,
    'clubName': clubName,
    'played': played,
    'wins': wins,
    'losses': losses,
    'points': points,
    'setsWon': setsWon,
    'setsLost': setsLost,
    'setDifference': setDifference,
    'abWins': abWins,
    'cdWins': cdWins,
    'womensWins': womensWins,
    'mixedWins': mixedWins,
    'hybridWins': hybridWins,
  };
}