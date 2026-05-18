class GetIptTournamentLeaderBoardModel {
  final bool? success;
  final Data? data;

  GetIptTournamentLeaderBoardModel({this.success, this.data});

  factory GetIptTournamentLeaderBoardModel.fromJson(
      Map<String, dynamic> json) {
    return GetIptTournamentLeaderBoardModel(
      success: json['success'] as bool?,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class Data {
  final List<String>? categories;
  final List<Leaderboard>? leaderboard;
  final String? filteredCategory; // ✅ added

  Data({
    this.categories,
    this.leaderboard,
    this.filteredCategory,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      categories: (json['categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      leaderboard: (json['leaderboard'] as List?)
          ?.map((e) => Leaderboard.fromJson(e))
          .toList(),
      filteredCategory: json['filteredCategory']?.toString(), // ✅ parse
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'leaderboard': leaderboard?.map((e) => e.toJson()).toList(),
      'filteredCategory': filteredCategory,
    };
  }
}

class Leaderboard {
  final String? teamId;
  final String? teamName;
  final int? played;
  final int? wins;
  final int? losses;
  final int? points;
  final int? setsWon;
  final int? setsLost;
  final int? setDifference;
  final int? previousPosition;
  final int? positionChange;
  final String? categoryType;
  final List<Player>? players; // ✅ added

  Leaderboard({
    this.teamId,
    this.teamName,
    this.played,
    this.wins,
    this.losses,
    this.points,
    this.setsWon,
    this.setsLost,
    this.setDifference,
    this.previousPosition,
    this.positionChange,
    this.categoryType,
    this.players,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      played: json['played'] as int?,
      wins: json['wins'] as int?,
      losses: json['losses'] as int?,
      points: json['points'] as int?,
      setsWon: json['setsWon'] as int?,
      setsLost: json['setsLost'] as int?,
      setDifference: json['setDifference'] as int?,
      previousPosition: json['previousPosition'] as int?,
      positionChange: json['positionChange'] as int?,
      categoryType: json['categoryType']?.toString(),

      // ✅ players parsing
      players: (json['players'] as List?)
          ?.map((e) => Player.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'played': played,
      'wins': wins,
      'losses': losses,
      'points': points,
      'setsWon': setsWon,
      'setsLost': setsLost,
      'setDifference': setDifference,
      'previousPosition': previousPosition,
      'positionChange': positionChange,
      'categoryType': categoryType,
      'players': players?.map((e) => e.toJson()).toList(),
    };
  }
}

class Player {
  final String? playerId;
  final String? playerName;
  final String? phoneNumber;

  Player({
    this.playerId,
    this.playerName,
    this.phoneNumber,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['playerId']?.toString(),
      playerName: json['playerName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'phoneNumber': phoneNumber,
    };
  }
}