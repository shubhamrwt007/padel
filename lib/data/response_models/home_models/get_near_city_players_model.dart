class GetNearCityPlayers {
  final bool? success;
  final Data? data;

  GetNearCityPlayers({this.success, this.data});

  factory GetNearCityPlayers.fromJson(Map<String, dynamic> json) {
    return GetNearCityPlayers(
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
  final String? city;
  final List<Leaderboard>? leaderboard;
  final MyRank? myRank;
  final Pagination? pagination;

  Data({this.city, this.leaderboard, this.myRank, this.pagination});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      city: json['city'],
      leaderboard: (json['leaderboard'] as List?)
          ?.map((e) => Leaderboard.fromJson(e))
          .toList(),
      myRank:
      json['myRank'] != null ? MyRank.fromJson(json['myRank']) : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    if (leaderboard != null)
      'leaderboard': leaderboard!.map((e) => e.toJson()).toList(),
    if (myRank != null) 'myRank': myRank!.toJson(),
    if (pagination != null) 'pagination': pagination!.toJson(),
  };
}

class Leaderboard {
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

  Leaderboard({
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

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
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

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'playerId': playerId,
    'name': name,
    'profilePic': profilePic,
    'xpPoints': xpPoints,
    'wins': wins,
    'matches': matches,
    'losses': losses,
    'currentWinStreak': currentWinStreak,
    'winRatio': winRatio,
    'isYou': isYou,
  };
}

class MyRank {
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

  MyRank({
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

  factory MyRank.fromJson(Map<String, dynamic> json) {
    return MyRank(
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

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'playerId': playerId,
    'name': name,
    'profilePic': profilePic,
    'xpPoints': xpPoints,
    'wins': wins,
    'matches': matches,
    'losses': losses,
    'currentWinStreak': currentWinStreak,
    'winRatio': winRatio,
    'isYou': isYou,
  };
}

class Pagination {
  final int? page;
  final int? limit;
  final int? totalPlayers;
  final int? totalPages;

  Pagination({this.page, this.limit, this.totalPlayers, this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      totalPlayers: json['totalPlayers'],
      totalPages: json['totalPages'],
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'totalPlayers': totalPlayers,
    'totalPages': totalPages,
  };
}
