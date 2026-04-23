class GetIptTournamentListModel {
  bool? success;
  List<Data>? data;
  Pagination? pagination;

  GetIptTournamentListModel({this.success, this.data, this.pagination});

  factory GetIptTournamentListModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentListModel(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => Data.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class Data {
  String? id;
  String? tournamentName;
  Registration? registration;
  MatchRules? matchRules;
  StateId? stateId;
  String? startDate;
  String? endDate;
  String? status;
  String? superAdminId;
  String? sportType;
  String? seasonType;
  bool? tournamentStatus;
  List<Category>? category;
  int? categoryCount;
  List<Sponsors>? sponsors;
  TitleSponsor? titleSponsor;
  List<PrizeDistribution>? prizeDistribution;
  Umpire? umpire;
  String? createdAt;
  String? updatedAt;

  Data.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    tournamentName = json['tournamentName'];

    registration = json['registration'] != null
        ? Registration.fromJson(json['registration'])
        : null;

    matchRules = json['matchRules'] != null
        ? MatchRules.fromJson(json['matchRules'])
        : null;

    stateId =
    json['stateId'] != null ? StateId.fromJson(json['stateId']) : null;

    startDate = json['startDate'];
    endDate = json['endDate'];
    status = json['status'];
    superAdminId = json['superAdminId'];
    sportType = json['sportType'];
    seasonType = json['seasonType'];
    tournamentStatus = json['tournamentStatus'];

    category = (json['category'] as List?)
        ?.map((e) => Category.fromJson(e))
        .toList();

    categoryCount = json['categoryCount'];

    sponsors = (json['sponsors'] as List?)
        ?.map((e) => Sponsors.fromJson(e))
        .toList();

    titleSponsor = json['titleSponsor'] != null
        ? TitleSponsor.fromJson(json['titleSponsor'])
        : null;

    prizeDistribution = (json['prizeDistribution'] as List?)
        ?.map((e) => PrizeDistribution.fromJson(e))
        .toList();

    umpire =
    json['umpire'] != null ? Umpire.fromJson(json['umpire']) : null;

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}

class Registration {
  String? startDate;
  String? endDate;
  bool? isEnabled;
  int? fee;

  Registration.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
    isEnabled = json['isEnabled'];
    fee = json['fee'];
  }
}

class MatchRules {
  Round? regularRound;
  Round? quarterfinal;
  Round? semifinal;
  Round? finalRound;

  MatchRules.fromJson(Map<String, dynamic> json) {
    regularRound = json['regularRound'] != null
        ? Round.fromJson(json['regularRound'])
        : null;

    quarterfinal = json['quarterfinal'] != null
        ? Round.fromJson(json['quarterfinal'])
        : null;

    semifinal = json['semifinal'] != null
        ? Round.fromJson(json['semifinal'])
        : null;

    finalRound =
    json['final'] != null ? Round.fromJson(json['final']) : null;
  }
}

class Round {
  bool? status;
  String? setsFormat;
  Settings? settings;

  Round.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    setsFormat = json['setsFormat'];
    settings =
    json['settings'] != null ? Settings.fromJson(json['settings']) : null;
  }
}

class Settings {
  int? numberOfSets;
  int? numberOfGames;
  bool? advantagesWithGoldenPoint;
  int? gamesToStartTiebreak;
  bool? goldenPoint;
  int? pointsInTiebreak;
  bool? tiebreakOnFinalSet;
  bool? goldenPointInTiebreak;
  int? matchWinPoints;

  Settings.fromJson(Map<String, dynamic> json) {
    numberOfSets = json['numberOfSets'];
    numberOfGames = json['numberOfGames'];
    advantagesWithGoldenPoint = json['advantagesWithGoldenPoint'];
    gamesToStartTiebreak = json['gamesToStartTiebreak'];
    goldenPoint = json['goldenPoint'];
    pointsInTiebreak = json['pointsInTiebreak'];
    tiebreakOnFinalSet = json['tiebreakOnFinalSet'];
    goldenPointInTiebreak = json['goldenPointInTiebreak'];
    matchWinPoints = json['matchWinPoints'];
  }
}

class StateId {
  String? id;
  String? name;

  StateId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
  }
}

class Category {
  String? id;
  String? categoryType;
  int? maxParticipants;
  String? tag;

  Category.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    categoryType = json['categoryType'];
    maxParticipants = json['maxParticipants'];
    tag = json['tag'];
  }
}

class Sponsors {
  String? name;
  dynamic categoryId; // 👈 safe (String or Map)
  String? logo;
  String? url;

  Sponsors.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    categoryId = json['categoryId']; // 👈 no crash
    logo = json['logo'];
    url = json['url'];
  }
}

class TitleSponsor {
  String? name;
  String? categoryId;
  String? logo;
  String? banner;
  String? url;

  TitleSponsor.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    categoryId = json['categoryId'];
    logo = json['logo'];
    banner = json['titleSponsorBanner'];
    url = json['url'];
  }
}

class PrizeDistribution {
  String? position;
  int? amount;

  PrizeDistribution.fromJson(Map<String, dynamic> json) {
    position = json['position'];
    amount = json['amount'];
  }
}

class Umpire {
  String? id;
  String? email;

  Umpire.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    email = json['email'];
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }
}