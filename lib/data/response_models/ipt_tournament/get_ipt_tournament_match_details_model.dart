class GetIptTournamentMatchDetailsModel {
  bool? success;
  HistoryData? history;
  StatisticsData? statistics;

  GetIptTournamentMatchDetailsModel({this.success, this.history, this.statistics});

  GetIptTournamentMatchDetailsModel.fromHistoryJson(Map<String, dynamic> json) {
    success = json['success'];
    history = json['data'] != null ? HistoryData.fromJson(json['data']) : null;
  }

  GetIptTournamentMatchDetailsModel.fromStatisticsJson(Map<String, dynamic> json) {
    success = json['success'];
    statistics =
    json['data'] != null ? StatisticsData.fromJson(json['data']) : null;
  }

  GetIptTournamentMatchDetailsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      final data = json['data'];
      if (data['statistics'] != null) {
        statistics = StatisticsData.fromJson(data);
      } else {
        history = HistoryData.fromJson(data);
      }
    }
  }
}

class HistoryData {
  String? matchId;
  String? status;
  String? winner;
  String? categoryType;
  Team? teamA;
  Team? teamB;
  CurrentPoints? currentPoints;
  SetsWon? setsWon;
  List<SetData>? sets;
  List<RoundTimeline>? roundTimeline;

  HistoryData(
      {this.matchId,
        this.status,
        this.winner,
        this.categoryType,
        this.teamA,
        this.teamB,
        this.currentPoints,
        this.setsWon,
        this.sets,
        this.roundTimeline});

  HistoryData.fromJson(Map<String, dynamic> json) {
    matchId = json['matchId'];
    status = json['status'];
    winner = json['winner'];
    categoryType = json['categoryType'];
    teamA = json['teamA'] != null ? Team.fromJson(json['teamA']) : null;
    teamB = json['teamB'] != null ? Team.fromJson(json['teamB']) : null;

    currentPoints = json['currentPoints'] != null
        ? CurrentPoints.fromJson(json['currentPoints'])
        : null;
    setsWon = json['setsWon'] != null
        ? SetsWon.fromJson(json['setsWon'])
        : null;

    if (json['sets'] != null) {
      sets = <SetData>[];
      json['sets'].forEach((v) {
        sets!.add(SetData.fromJson(v));
      });
    }

    if (json['roundTimeline'] != null) {
      roundTimeline = <RoundTimeline>[];
      json['roundTimeline'].forEach((v) {
        roundTimeline!.add(RoundTimeline.fromJson(v));
      });
    }
  }
}

class StatisticsData {
  String? matchId;
  String? scheduleId;
  MatchStatistics? statistics;
  int? totalEvents;

  StatisticsData({this.matchId, this.scheduleId, this.statistics, this.totalEvents});

  StatisticsData.fromJson(Map<String, dynamic> json) {
    matchId = json['matchId'];
    scheduleId = json['scheduleId'];

    statistics = json['statistics'] != null
        ? MatchStatistics.fromJson(json['statistics'])
        : null;

    totalEvents = json['totalEvents'];
  }
}

class MatchStatistics {
  StatisticsTeam? teamA;
  StatisticsTeam? teamB;

  MatchStatistics({this.teamA, this.teamB});

  MatchStatistics.fromJson(Map<String, dynamic> json) {
    teamA =
    json['teamA'] != null ? StatisticsTeam.fromJson(json['teamA']) : null;
    teamB =
    json['teamB'] != null ? StatisticsTeam.fromJson(json['teamB']) : null;
  }
}

class StatisticsTeam {
  int? winners;
  int? errors;
  int? forcedErrors;
  int? unforcedErrors;
  int? faults;
  int? totalPoints;
  int? breakPointOpportunities;
  int? breakPointsWon;
  int? breakPointsSaved;
  int? goldenPoints;
  int? firstServeIn;
  int? firstServeOut;
  int? firstServePercentage;
  int? aces;
  int? doubleFaults;

  StatisticsTeam(
      {
        this.winners,
        this.errors,
        this.forcedErrors,
        this.unforcedErrors,
        this.faults,
        this.totalPoints,
        this.breakPointOpportunities,
        this.breakPointsWon,
        this.breakPointsSaved,
        this.goldenPoints,
        this.firstServeIn,
        this.firstServeOut,
        this.firstServePercentage,
        this.aces,
        this.doubleFaults});

  StatisticsTeam.fromJson(Map<String, dynamic> json) {
    winners = json['winners'];
    errors = json['errors'];
    forcedErrors = json['forcedErrors'];
    unforcedErrors = json['unforcedErrors'];
    faults = json['faults'];
    totalPoints = json['totalPoints'];
    breakPointOpportunities = json['breakPointOpportunities'];
    breakPointsWon = json['breakPointsWon'];
    breakPointsSaved = json['breakPointsSaved'];
    goldenPoints = json['goldenPoints'];
    firstServeIn = json['firstServeIn'];
    firstServeOut = json['firstServeOut'];
    firstServePercentage = json['firstServePercentage'];
    aces = json['aces'];
    doubleFaults = json['doubleFaults'];
  }
}

class Team {
  String? teamId;
  String? teamName;
  String? clubName;
  List<Player>? players;

  Team({this.teamId, this.teamName, this.clubName, this.players});

  Team.fromJson(Map<String, dynamic> json) {
    teamId = json['teamId'];
    teamName = json['teamName'];
    clubName = json['clubName'];

    if (json['players'] != null) {
      players = <Player>[];
      json['players'].forEach((v) {
        players!.add(Player.fromJson(v));
      });
    }
  }
}

class Player {
  String? playerId;
  String? playerName;
  String? sId;

  Player({this.playerId, this.playerName, this.sId});

  Player.fromJson(Map<String, dynamic> json) {
    playerId = json['playerId'];
    playerName = json['playerName'];
    sId = json['_id'];
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
}
class SetsWon {
  int? teamA;
  int? teamB;

  SetsWon({this.teamA, this.teamB});

  SetsWon.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'];
    teamB = json['teamB'];
  }
}

class SetData {
  int? setNumber;
  FinalScore? finalScore;
  List<RoundData>? rounds;
  String? setWinner;

  SetData({this.setNumber, this.finalScore, this.rounds, this.setWinner});

  SetData.fromJson(Map<String, dynamic> json) {
    setNumber = json['setNumber'];
    finalScore = json['finalScore'] != null ? FinalScore.fromJson(json['finalScore']) : null;
    setWinner = json['setWinner'];
    if (json['rounds'] != null) {
      rounds = <RoundData>[];
      json['rounds'].forEach((v) {
        rounds!.add(RoundData.fromJson(v));
      });
    }
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
}

class RoundData {
  int? round;
  FinalScore? score;
  CurrentPoints? pointsAtEnd;
  String? completedAt;
  String? gameWinner;
  String? winType;

  RoundData({this.round, this.score, this.pointsAtEnd, this.completedAt, this.gameWinner,this.winType});

  RoundData.fromJson(Map<String, dynamic> json) {
    round = json['round'];
    score = json['score'] != null ? FinalScore.fromJson(json['score']) : null;
    pointsAtEnd = json['pointsAtEnd'] != null ? CurrentPoints.fromJson(json['pointsAtEnd']) : null;
    completedAt = json['completedAt'];
    gameWinner = json['gameWinner'];
    winType = json['winType'];
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
}