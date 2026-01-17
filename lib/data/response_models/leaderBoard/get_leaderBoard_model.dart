class GetLeaderBoardModel {
  final bool? success;
  final LeaderboardData? data;

  GetLeaderBoardModel({this.success, this.data});

  factory GetLeaderBoardModel.fromJson(Map<String, dynamic> json) {
    return GetLeaderBoardModel(
      success: json['success'],
      data: json['data'] != null
          ? LeaderboardData.fromJson(json['data'])
          : null,
    );
  }
}

/* ===================== DATA ===================== */

class LeaderboardData {
  final List<LeaderboardPlayer>? topThree;
  final List<LeaderboardPlayer>? leaderboard;
  final Pagination? pagination;
  final LeaderboardPlayer? myRank;

  LeaderboardData({
    this.topThree,
    this.leaderboard,
    this.pagination,
    this.myRank,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      topThree: (json['topThree'] as List?)
          ?.map((e) => LeaderboardPlayer.fromJson(e))
          .toList(),
      leaderboard: (json['leaderboard'] as List?)
          ?.map((e) => LeaderboardPlayer.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      myRank: json['myRank'] != null
          ? LeaderboardPlayer.fromJson(json['myRank'])
          : null,
    );
  }
}

/* ===================== PLAYER ===================== */

class LeaderboardPlayer {
  final int? rank;
  final String? playerId;
  final String? name;
  final String? profilePic;
  final int? xpPoints;
  final int? wins;
  final int? matches;
  final int? losses;
  final int? currentWinStreak;
  final double? winRatio;
  final bool? isYou;

  LeaderboardPlayer({
    this.rank,
    this.playerId,
    this.name,
    this.profilePic,
    this.xpPoints,
    this.wins,
    this.matches,
    this.losses,
    this.currentWinStreak,
    this.winRatio,
    this.isYou,
  });

  factory LeaderboardPlayer.fromJson(Map<String, dynamic> json) {
    return LeaderboardPlayer(
      rank: json['rank'],
      playerId: json['playerId'],
      name: json['name'],
      profilePic: json['profilePic'],
      xpPoints: json['xpPoints'],
      wins: json['wins'],
      matches: json['matches'],
      losses: json['losses'],
      currentWinStreak: json['currentWinStreak'],
      winRatio: (json['winRatio'] as num?)?.toDouble(),
      isYou: json['isYou'],
    );
  }
}

/* ===================== PAGINATION ===================== */

class Pagination {
  final int? page;
  final int? limit;
  final int? totalPlayers;
  final int? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.totalPlayers,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      totalPlayers: json['totalPlayers'],
      totalPages: json['totalPages'],
    );
  }
}
