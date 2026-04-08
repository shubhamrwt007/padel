class ScoreStatisticModel {
  bool? success;
  Data? data;

  ScoreStatisticModel({this.success, this.data});

  ScoreStatisticModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? matchId;
  String? scheduleId;
  Statistics? statistics;
  int? totalEvents;

  Data({this.matchId, this.scheduleId, this.statistics, this.totalEvents});

  Data.fromJson(Map<String, dynamic> json) {
    matchId = json['matchId'];
    scheduleId = json['scheduleId'];
    statistics = json['statistics'] != null
        ? new Statistics.fromJson(json['statistics'])
        : null;
    totalEvents = json['totalEvents'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['matchId'] = this.matchId;
    data['scheduleId'] = this.scheduleId;
    if (this.statistics != null) {
      data['statistics'] = this.statistics!.toJson();
    }
    data['totalEvents'] = this.totalEvents;
    return data;
  }
}

class Statistics {
  TeamA? teamA;
  TeamA? teamB;

  Statistics({this.teamA, this.teamB});

  Statistics.fromJson(Map<String, dynamic> json) {
    teamA = json['teamA'] != null ? new TeamA.fromJson(json['teamA']) : null;
    teamB = json['teamB'] != null ? new TeamA.fromJson(json['teamB']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.teamA != null) {
      data['teamA'] = this.teamA!.toJson();
    }
    if (this.teamB != null) {
      data['teamB'] = this.teamB!.toJson();
    }
    return data;
  }
}

class TeamA {
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

  TeamA(
      {this.winners,
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

  TeamA.fromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['winners'] = this.winners;
    data['errors'] = this.errors;
    data['forcedErrors'] = this.forcedErrors;
    data['unforcedErrors'] = this.unforcedErrors;
    data['faults'] = this.faults;
    data['totalPoints'] = this.totalPoints;
    data['breakPointOpportunities'] = this.breakPointOpportunities;
    data['breakPointsWon'] = this.breakPointsWon;
    data['breakPointsSaved'] = this.breakPointsSaved;
    data['goldenPoints'] = this.goldenPoints;
    data['firstServeIn'] = this.firstServeIn;
    data['firstServeOut'] = this.firstServeOut;
    data['firstServePercentage'] = this.firstServePercentage;
    data['aces'] = this.aces;
    data['doubleFaults'] = this.doubleFaults;
    return data;
  }
}
