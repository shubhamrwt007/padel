class ScoreHistoryModel {
  bool? success;
  Data? data;

  ScoreHistoryModel({this.success, this.data});

  ScoreHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? matchId;
  String? status;
  String? winner;
  TeamA? teamA;
  TeamA? teamB;
  CurrentPoints? currentPoints;
  SetWon? setsWon;
  List<Sets>? sets;
  List<RoundTimeline>? roundTimeline;

  Data(
      {this.matchId,
        this.status,
        this.winner,
        this.teamA,
        this.teamB,
        this.currentPoints,
        this.setsWon,
        this.sets,
        this.roundTimeline});

  Data.fromJson(Map<String, dynamic> json) {
    matchId = json['matchId'];
    status = json['status'];
    winner = json['winner'];
    teamA = json['teamA'] != null ? TeamA.fromJson(json['teamA']) : null;
    teamB = json['teamB'] != null ? TeamA.fromJson(json['teamB']) : null;

    currentPoints = json['currentPoints'] != null
        ? CurrentPoints.fromJson(json['currentPoints'])
        : null;

    setsWon =
    json['setsWon'] != null ? SetWon.fromJson(json['setsWon']) : null;

    if (json['sets'] != null) {
      sets = <Sets>[];
      json['sets'].forEach((v) {
        sets!.add(Sets.fromJson(v));
      });
    }

    if (json['roundTimeline'] != null) {
      roundTimeline = <RoundTimeline>[];
      json['roundTimeline'].forEach((v) {
        roundTimeline!.add(RoundTimeline.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['matchId'] = matchId;
    data['status'] = status;
    data['winner'] = winner;

    if (teamA != null) {
      data['teamA'] = teamA!.toJson();
    }

    if (teamB != null) {
      data['teamB'] = teamB!.toJson();
    }

    if (currentPoints != null) {
      data['currentPoints'] = currentPoints!.toJson();
    }

    if (setsWon != null) {
      data['setsWon'] = setsWon!.toJson();
    }

    if (sets != null) {
      data['sets'] = sets!.map((v) => v.toJson()).toList();
    }

    if (roundTimeline != null) {
      data['roundTimeline'] =
          roundTimeline!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class TeamA {
  String? teamId;
  String? teamName;
  String? clubId;
  String? clubName;
  String? level;
  List<Players>? players;

  TeamA(
      {this.teamId,
        this.teamName,
        this.clubId,
        this.clubName,
        this.level,
        this.players});

  TeamA.fromJson(Map<String, dynamic> json) {
    teamId = json['teamId'];
    teamName = json['teamName'];
    clubId = json['clubId'];
    clubName = json['clubName'];
    level = json['level'];

    if (json['players'] != null) {
      players = <Players>[];
      json['players'].forEach((v) {
        players!.add(Players.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['teamId'] = teamId;
    data['teamName'] = teamName;
    data['clubId'] = clubId;
    data['clubName'] = clubName;
    data['level'] = level;

    if (players != null) {
      data['players'] = players!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Players {
  String? playerId;
  String? playerName;
  String? sId;

  Players({this.playerId, this.playerName, this.sId});

  Players.fromJson(Map<String, dynamic> json) {
    playerId = json['playerId'];
    playerName = json['playerName'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['playerId'] = playerId;
    data['playerName'] = playerName;
    data['_id'] = sId;
    return data;
  }
}

class CurrentPoints {
  String? teamA;
  String? teamB;

  CurrentPoints({this.teamA, this.teamB});

  CurrentPoints.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['teamA'] = teamA;
    data['teamB'] = teamB;
    return data;
  }
}

class SetWon {
  int? teamA;
  int? teamB;

  SetWon({this.teamA, this.teamB});

  SetWon.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['teamA'] = teamA;
    data['teamB'] = teamB;
    return data;
  }
}

class Sets {
  int? setNumber;
  String? setWinner;
  FinalScore? finalScore;
  List<Rounds>? rounds;

  Sets({this.setNumber, this.setWinner, this.finalScore, this.rounds});

  Sets.fromJson(Map<String, dynamic> json) {
    setNumber = json['setNumber'];
    setWinner = json['setWinner'];

    finalScore = json['finalScore'] != null
        ? FinalScore.fromJson(json['finalScore'])
        : null;

    if (json['rounds'] != null) {
      rounds = <Rounds>[];
      json['rounds'].forEach((v) {
        rounds!.add(Rounds.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['setNumber'] = setNumber;
    data['setWinner'] = setWinner;

    if (finalScore != null) {
      data['finalScore'] = finalScore!.toJson();
    }

    if (rounds != null) {
      data['rounds'] = rounds!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class FinalScore {
  int? teamA;
  int? teamB;

  FinalScore({this.teamA, this.teamB});

  FinalScore.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['teamA'] = teamA;
    data['teamB'] = teamB;
    return data;
  }
}

class Rounds {
  int? round;
  String? gameWinner;
  int? deuceCount;
  FinalScore? score;
  CurrentPoints? pointsAtEnd;
  String? completedAt;

  Rounds(
      {this.round,
        this.gameWinner,
        this.deuceCount,
        this.score,
        this.pointsAtEnd,
        this.completedAt});

  Rounds.fromJson(Map<String, dynamic> json) {
    round = json['round'];
    gameWinner = json['gameWinner'];
    deuceCount = json['deuceCount'];

    score =
    json['score'] != null ? FinalScore.fromJson(json['score']) : null;

    pointsAtEnd = json['pointsAtEnd'] != null
        ? CurrentPoints.fromJson(json['pointsAtEnd'])
        : null;

    completedAt = json['completedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['round'] = round;
    data['gameWinner'] = gameWinner;
    data['deuceCount'] = deuceCount;

    if (score != null) {
      data['score'] = score!.toJson();
    }

    if (pointsAtEnd != null) {
      data['pointsAtEnd'] = pointsAtEnd!.toJson();
    }

    data['completedAt'] = completedAt;

    return data;
  }
}

class RoundTimeline {
  String? eventType;
  String? team;
  String? timestamp;

  RoundTimeline({this.eventType, this.team, this.timestamp});

  RoundTimeline.fromJson(Map<String, dynamic> json) {
    eventType = json['eventType'];
    team = json['team'];
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['eventType'] = eventType;
    data['team'] = team;
    data['timestamp'] = timestamp;
    return data;
  }
}