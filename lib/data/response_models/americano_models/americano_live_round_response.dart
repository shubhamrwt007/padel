class AmericanoLiveRoundResponse {
  bool? success;
  LiveRoundData? data;

  AmericanoLiveRoundResponse({this.success, this.data});

  AmericanoLiveRoundResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? LiveRoundData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class LiveRoundData {
  AmericanoDetail? americano;
  RoundDetail? round;
  String? roundId;
  String? americanoMatchId;
  String? status;
  String? court;
  int? courtNo;
  String? streamKey;
  String? youtubeUrl;
  String? youtubeVideoId;
  String? youtubeEmbedUrl;
  String? scoreboardUrl;
  LiveScore? score;
  LiveStats? stats;
  RoundTeam? teamA;
  RoundTeam? teamB;
  List<LivePointHistoryItem>? pointHistory;

  LiveRoundData({
    this.americano,
    this.round,
    this.roundId,
    this.americanoMatchId,
    this.status,
    this.court,
    this.courtNo,
    this.streamKey,
    this.youtubeUrl,
    this.youtubeVideoId,
    this.youtubeEmbedUrl,
    this.scoreboardUrl,
    this.score,
    this.stats,
    this.teamA,
    this.teamB,
    this.pointHistory,
  });

  LiveRoundData.fromJson(Map<String, dynamic> json) {
    americano = json['americano'] != null ? AmericanoDetail.fromJson(json['americano']) : null;
    round = json['round'] != null ? RoundDetail.fromJson(json['round']) : null;
    roundId = json['roundId']?.toString();
    americanoMatchId = json['americanoMatchId']?.toString();
    status = json['status']?.toString();
    court = json['court']?.toString();
    courtNo = json['courtNo'] is int ? json['courtNo'] : int.tryParse(json['courtNo']?.toString() ?? '');
    streamKey = json['streamKey']?.toString();
    youtubeUrl = json['youtubeUrl']?.toString();
    youtubeVideoId = json['youtubeVideoId']?.toString();
    youtubeEmbedUrl = json['youtubeEmbedUrl']?.toString();
    scoreboardUrl = json['scoreboardUrl']?.toString();
    score = json['score'] != null ? LiveScore.fromJson(json['score']) : null;
    stats = json['stats'] != null ? LiveStats.fromJson(json['stats']) : null;
    teamA = json['teamA'] != null ? RoundTeam.fromJson(json['teamA']) : null;
    teamB = json['teamB'] != null ? RoundTeam.fromJson(json['teamB']) : null;

    if (json['pointHistory'] != null && json['pointHistory'] is List) {
      pointHistory = <LivePointHistoryItem>[];
      for (var v in json['pointHistory']) {
        if (v is Map<String, dynamic>) {
          pointHistory!.add(LivePointHistoryItem.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (americano != null) map['americano'] = americano!.toJson();
    if (round != null) map['round'] = round!.toJson();
    map['roundId'] = roundId;
    map['americanoMatchId'] = americanoMatchId;
    map['status'] = status;
    map['court'] = court;
    map['courtNo'] = courtNo;
    map['streamKey'] = streamKey;
    map['youtubeUrl'] = youtubeUrl;
    map['youtubeVideoId'] = youtubeVideoId;
    map['youtubeEmbedUrl'] = youtubeEmbedUrl;
    map['scoreboardUrl'] = scoreboardUrl;
    if (score != null) map['score'] = score!.toJson();
    if (stats != null) map['stats'] = stats!.toJson();
    if (teamA != null) map['teamA'] = teamA!.toJson();
    if (teamB != null) map['teamB'] = teamB!.toJson();
    if (pointHistory != null) {
      map['pointHistory'] = pointHistory!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class AmericanoDetail {
  String? sId;
  ClubInfo? clubId;
  OwnerInfo? ownerId;
  String? matchTitle;
  String? matchDescription;
  String? skillLevel;
  String? americanoFormat;

  AmericanoDetail({
    this.sId,
    this.clubId,
    this.ownerId,
    this.matchTitle,
    this.matchDescription,
    this.skillLevel,
    this.americanoFormat,
  });

  AmericanoDetail.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubId = json['clubId'] != null ? ClubInfo.fromJson(json['clubId']) : null;
    ownerId = json['ownerId'] != null ? OwnerInfo.fromJson(json['ownerId']) : null;
    matchTitle = json['matchTitle']?.toString();
    matchDescription = json['matchDescription']?.toString();
    skillLevel = json['skillLevel']?.toString();
    americanoFormat = json['americanoFormat']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    if (clubId != null) map['clubId'] = clubId!.toJson();
    if (ownerId != null) map['ownerId'] = ownerId!.toJson();
    map['matchTitle'] = matchTitle;
    map['matchDescription'] = matchDescription;
    map['skillLevel'] = skillLevel;
    map['americanoFormat'] = americanoFormat;
    return map;
  }
}

class ClubInfo {
  String? sId;
  String? clubName;
  String? logo;

  ClubInfo({this.sId, this.clubName, this.logo});

  ClubInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    clubName = json['clubName']?.toString();
    logo = json['logo']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    map['clubName'] = clubName;
    map['logo'] = logo;
    return map;
  }
}

class OwnerInfo {
  String? sId;
  String? email;
  String? name;

  OwnerInfo({this.sId, this.email, this.name});

  OwnerInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    email = json['email']?.toString();
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    map['email'] = email;
    map['name'] = name;
    return map;
  }
}

class RoundDetail {
  String? sId;
  String? americanoMatchId;
  String? americanoFormat;
  int? roundNo;
  int? matchNo;
  int? courtNo;
  String? status;
  String? winner;
  String? servingTeam;
  int? serverIndex;
  String? scoreboardUrl;
  String? streamKey;
  String? youtubeEmbedUrl;
  String? youtubeUrl;
  String? youtubeVideoId;

  RoundDetail({
    this.sId,
    this.americanoMatchId,
    this.americanoFormat,
    this.roundNo,
    this.matchNo,
    this.courtNo,
    this.status,
    this.winner,
    this.servingTeam,
    this.serverIndex,
    this.scoreboardUrl,
    this.streamKey,
    this.youtubeEmbedUrl,
    this.youtubeUrl,
    this.youtubeVideoId,
  });

  RoundDetail.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    americanoMatchId = json['americanoMatchId']?.toString();
    americanoFormat = json['americanoFormat']?.toString();
    roundNo = json['roundNo'] is int ? json['roundNo'] : int.tryParse(json['roundNo']?.toString() ?? '');
    matchNo = json['matchNo'] is int ? json['matchNo'] : int.tryParse(json['matchNo']?.toString() ?? '');
    courtNo = json['courtNo'] is int ? json['courtNo'] : int.tryParse(json['courtNo']?.toString() ?? '');
    status = json['status']?.toString();
    winner = json['winner']?.toString();
    servingTeam = json['servingTeam']?.toString();
    serverIndex = json['serverIndex'] is int ? json['serverIndex'] : int.tryParse(json['serverIndex']?.toString() ?? '');
    scoreboardUrl = json['scoreboardUrl']?.toString();
    streamKey = json['streamKey']?.toString();
    youtubeEmbedUrl = json['youtubeEmbedUrl']?.toString();
    youtubeUrl = json['youtubeUrl']?.toString();
    youtubeVideoId = json['youtubeVideoId']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['_id'] = sId;
    map['americanoMatchId'] = americanoMatchId;
    map['americanoFormat'] = americanoFormat;
    map['roundNo'] = roundNo;
    map['matchNo'] = matchNo;
    map['courtNo'] = courtNo;
    map['status'] = status;
    map['winner'] = winner;
    map['servingTeam'] = servingTeam;
    map['serverIndex'] = serverIndex;
    map['scoreboardUrl'] = scoreboardUrl;
    map['streamKey'] = streamKey;
    map['youtubeEmbedUrl'] = youtubeEmbedUrl;
    map['youtubeUrl'] = youtubeUrl;
    map['youtubeVideoId'] = youtubeVideoId;
    return map;
  }
}

class RoundTeam {
  String? teamName;
  List<LivePlayer>? players;
  int? points;
  int? faults;
  int? errors;
  int? forcedErrors;

  RoundTeam({
    this.teamName,
    this.players,
    this.points,
    this.faults,
    this.errors,
    this.forcedErrors,
  });

  RoundTeam.fromJson(Map<String, dynamic> json) {
    teamName = json['teamName']?.toString();
    if (json['players'] != null && json['players'] is List) {
      players = <LivePlayer>[];
      for (var v in json['players']) {
        if (v is Map<String, dynamic>) {
          players!.add(LivePlayer.fromJson(v));
        }
      }
    }
    points = json['points'] is int ? json['points'] : int.tryParse(json['points']?.toString() ?? '');
    faults = json['faults'] is int ? json['faults'] : int.tryParse(json['faults']?.toString() ?? '');
    errors = json['errors'] is int ? json['errors'] : int.tryParse(json['errors']?.toString() ?? '');
    forcedErrors = json['forcedErrors'] is int ? json['forcedErrors'] : int.tryParse(json['forcedErrors']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['teamName'] = teamName;
    if (players != null) {
      map['players'] = players!.map((v) => v.toJson()).toList();
    }
    map['points'] = points;
    map['faults'] = faults;
    map['errors'] = errors;
    map['forcedErrors'] = forcedErrors;
    return map;
  }
}

class LivePlayer {
  String? americanoPlayerId;
  String? fullName;
  String? phoneNumber;
  String? email;
  String? gender;
  String? playerLevel;

  LivePlayer({
    this.americanoPlayerId,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.gender,
    this.playerLevel,
  });

  LivePlayer.fromJson(Map<String, dynamic> json) {
    americanoPlayerId = json['americanoPlayerId']?.toString();
    fullName = json['fullName']?.toString();
    phoneNumber = json['phoneNumber']?.toString();
    email = json['email']?.toString();
    gender = json['gender']?.toString();
    playerLevel = json['playerLevel']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['americanoPlayerId'] = americanoPlayerId;
    map['fullName'] = fullName;
    map['phoneNumber'] = phoneNumber;
    map['email'] = email;
    map['gender'] = gender;
    map['playerLevel'] = playerLevel;
    return map;
  }
}

class LiveScore {
  int? teamA;
  int? teamB;
  int? total;
  int? maxPoints;
  bool? isMaxPointsReached;

  LiveScore({this.teamA, this.teamB, this.total, this.maxPoints, this.isMaxPointsReached});

  LiveScore.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'] is int ? json['teamA'] : int.tryParse(json['teamA']?.toString() ?? '');
    teamB = json['teamB'] is int ? json['teamB'] : int.tryParse(json['teamB']?.toString() ?? '');
    total = json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '');
    maxPoints = json['maxPoints'] is int ? json['maxPoints'] : int.tryParse(json['maxPoints']?.toString() ?? '');
    isMaxPointsReached = json['isMaxPointsReached'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['teamA'] = teamA;
    map['teamB'] = teamB;
    map['total'] = total;
    map['maxPoints'] = maxPoints;
    map['isMaxPointsReached'] = isMaxPointsReached;
    return map;
  }
}

class LiveStats {
  TeamStats? teamA;
  TeamStats? teamB;

  LiveStats({this.teamA, this.teamB});

  LiveStats.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'] != null ? TeamStats.fromJson(json['teamA']) : null;
    teamB = json['teamB'] != null ? TeamStats.fromJson(json['teamB']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (teamA != null) map['teamA'] = teamA!.toJson();
    if (teamB != null) map['teamB'] = teamB!.toJson();
    return map;
  }
}

class TeamStats {
  int? faults;
  int? errors;
  int? forcedErrors;

  TeamStats({this.faults, this.errors, this.forcedErrors});

  TeamStats.fromJson(Map<String, dynamic> json) {
    faults = json['faults'] is int ? json['faults'] : int.tryParse(json['faults']?.toString() ?? '');
    errors = json['errors'] is int ? json['errors'] : int.tryParse(json['errors']?.toString() ?? '');
    forcedErrors = json['forcedErrors'] is int ? json['forcedErrors'] : int.tryParse(json['forcedErrors']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['faults'] = faults;
    map['errors'] = errors;
    map['forcedErrors'] = forcedErrors;
    return map;
  }
}

class LivePointHistoryItem {
  String? winner;
  int? teamAScore;
  int? teamBScore;
  String? recordedAt;
  int? pointNo;

  LivePointHistoryItem({this.winner, this.teamAScore, this.teamBScore, this.recordedAt, this.pointNo});

  LivePointHistoryItem.fromJson(Map<String, dynamic> json) {
    winner = json['winner']?.toString();
    teamAScore = json['teamAScore'] is int ? json['teamAScore'] : int.tryParse(json['teamAScore']?.toString() ?? '');
    teamBScore = json['teamBScore'] is int ? json['teamBScore'] : int.tryParse(json['teamBScore']?.toString() ?? '');
    recordedAt = json['recordedAt']?.toString();
    pointNo = json['pointNo'] is int ? json['pointNo'] : int.tryParse(json['pointNo']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['winner'] = winner;
    map['teamAScore'] = teamAScore;
    map['teamBScore'] = teamBScore;
    map['recordedAt'] = recordedAt;
    map['pointNo'] = pointNo;
    return map;
  }
}
