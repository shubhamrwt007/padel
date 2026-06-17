class GetXpPointsModel {
  final bool? success;
  final String? message;
  final List<XpData>? data;
  final Pagination? pagination;
  final Summary? summary;
  final CurrentXp? currentXp; // 👈 add this

  GetXpPointsModel({
    this.success,
    this.message,
    this.data,
    this.pagination,
    this.summary,
    this.currentXp,
  });

  factory GetXpPointsModel.fromJson(Map<String, dynamic> json) {
    return GetXpPointsModel(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List?)
          ?.map((e) => XpData.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      summary:
      json['summary'] != null ? Summary.fromJson(json['summary']) : null,

      // 👇 parse currentXp
      currentXp: json['currentXp'] != null
          ? CurrentXp.fromJson(json['currentXp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.map((e) => e.toJson()).toList(),
    'pagination': pagination?.toJson(),
    'summary': summary?.toJson(),
    'currentXp': currentXp?.toJson(),
  };
}

class XpData {
  final String? id;
  final String? userId;
  final String? bookingId;
  final LeagueMatchId? leagueMatchId;
  final ScoreboardId? scoreboardId;
  final dynamic? xpChange;
  final String? result;
  final String? createdAt;
  final int? version;

  XpData({
    this.id,
    this.userId,
    this.bookingId,
    this.scoreboardId,
    this.leagueMatchId,
    this.xpChange,
    this.result,
    this.createdAt,
    this.version,
  });

  factory XpData.fromJson(Map<String, dynamic> json) {
    return XpData(
      id: json['_id'],
      userId: json['userId'],
      bookingId: json['bookingId'],
      scoreboardId: json['scoreboardId'] != null
          ? ScoreboardId.fromJson(json['scoreboardId'])
          : null,
      leagueMatchId: json['matchId'] != null // 👈 key same rahegi
          ? LeagueMatchId.fromJson(json['matchId'])
          : null,
      xpChange: json['xpChange'],
      result: json['result'],
      createdAt: json['createdAt'],
      version: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'bookingId': bookingId,
    'userId': userId,
    'scoreboardId': scoreboardId?.toJson(),
    'matchId': leagueMatchId?.toJson(),
    'xpChange': xpChange,
    'result': result,
    'createdAt': createdAt,
    '__v': version,
  };
}
class LeagueMatchId {
  final String? id;
  final String? scheduleId;
  final String? startTime;
  final String? endTime;

  LeagueMatchId({
    this.id,
    this.scheduleId,
    this.startTime,
    this.endTime,
  });

  factory LeagueMatchId.fromJson(Map<String, dynamic> json) {
    return LeagueMatchId(
      id: json['_id'],
      scheduleId: json['scheduleId'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'scheduleId': scheduleId,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class ScoreboardId {
  final String? id;
  final String? startTime;
  final String? endTime;
  final String? createdAt;

  ScoreboardId({
    this.id,
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  factory ScoreboardId.fromJson(Map<String, dynamic> json) {
    return ScoreboardId(
      id: json['_id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'startTime': startTime,
    'endTime': endTime,
    'createdAt': createdAt,
  };
}

class Pagination {
  final int? page;
  final int? limit;
  final int? totalRecords;
  final int? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.totalRecords,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      totalRecords: json['totalRecords'],
      totalPages: json['totalPages'],
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'totalRecords': totalRecords,
    'totalPages': totalPages,
  };
}

class Summary {
  final String? id;
  final dynamic? totalXpGained;
  final dynamic? totalXpLost;

  Summary({
    this.id,
    this.totalXpGained,
    this.totalXpLost,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['_id'],
      totalXpGained: json['totalXpGained'],
      totalXpLost: json['totalXpLost'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'totalXpGained': totalXpGained,
    'totalXpLost': totalXpLost,
  };
}
class CurrentXp {
  final String? categoryId;
  final String? sport;
  final dynamic xpPoints;
  final String? level;
  final dynamic pickleballTier;
  final dynamic pickleballTierLabel;

  CurrentXp({
    this.categoryId,
    this.sport,
    this.xpPoints,
    this.level,
    this.pickleballTier,
    this.pickleballTierLabel,
  });

  factory CurrentXp.fromJson(Map<String, dynamic> json) {
    return CurrentXp(
      categoryId: json['categoryId'],
      sport: json['sport'],
      xpPoints: json['xpPoints'],
      level: json['level'],
      pickleballTier: json['pickleballTier'],
      pickleballTierLabel: json['pickleballTierLabel'],
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'sport': sport,
    'xpPoints': xpPoints,
    'level': level,
    'pickleballTier': pickleballTier,
    'pickleballTierLabel': pickleballTierLabel,
  };
}
