class GetLeagueListModel {
  bool? success;
  List<Data>? data;
  Pagination? pagination;

  GetLeagueListModel({this.success, this.data, this.pagination});

  factory GetLeagueListModel.fromJson(Map<String, dynamic> json) {
    return GetLeagueListModel(
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
  Registration? registration;
  TitleSponsor? titleSponsor;
  String? id;
  String? leagueName;
  StateId? stateId;
  String? startDate;
  String? endDate;
  List<Clubs>? clubs;
  int? bounty;
  int? teamOfLeague;
  String? status;
  int? totalPaymentReceived;
  String? superAdminId;
  String? sportType;
  String? seasonType;
  bool? leagueStatus;
  List<Sponsors>? sponsors;
  List<PrizeDistribution>? prizeDistribution;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? bountyCondition;
  int? clubCount;
  String? mobileBanner;
  String? webBanner;

  Data.fromJson(Map<String, dynamic> json) {
    registration = json['registration'] != null
        ? Registration.fromJson(json['registration'])
        : null;
    titleSponsor = json['titleSponsor'] != null
        ? TitleSponsor.fromJson(json['titleSponsor'])
        : null;


    id = json['_id'];
    leagueName = json['leagueName'];
    stateId =
    json['stateId'] != null ? StateId.fromJson(json['stateId']) : null;

    startDate = json['startDate'];
    endDate = json['endDate'];

    clubs = (json['clubs'] as List?)
        ?.map((e) => Clubs.fromJson(e))
        .toList();

    bounty = json['bounty'];
    teamOfLeague = json['teamOfLeague'];
    status = json['status'];
    totalPaymentReceived = json['totalPaymentReceived'];
    superAdminId = json['superAdminId'];
    sportType = json['sportType'];
    seasonType = json['seasonType'];
    leagueStatus = json['leagueStatus'];

    sponsors = (json['sponsors'] as List?)
        ?.map((e) => Sponsors.fromJson(e))
        .toList();

    prizeDistribution = (json['prizeDistribution'] as List?)
        ?.map((e) => PrizeDistribution.fromJson(e))
        .toList();

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    bountyCondition = json['bountyCondition'];
    clubCount = json['clubCount'];
    mobileBanner = json['mobileBanner'];
    webBanner = json['webBanner'];
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

class TitleSponsor {
  String? name;
  String? categoryId;
  String? logo;
  String? banner;

  TitleSponsor.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    categoryId = json['categoryId'];
    logo = json['logo'];
    banner = json['titleSponsorBanner'];
  }
}


class RegularRound {
  bool? status;
  String? setsFormat;
  Settings? settings;

  RegularRound.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    setsFormat = json['setsFormat'];
    settings =
    json['settings'] != null ? Settings.fromJson(json['settings']) : null;
  }
}

class Settings {
  int? numberOfSets;
  int? numberOfGames;

  Settings.fromJson(Map<String, dynamic> json) {
    numberOfSets = json['numberOfSets'];
    numberOfGames = json['numberOfGames'];
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

class Clubs {
  ClubId? clubId;
  List<String>? registeredPlayers;

  Clubs.fromJson(Map<String, dynamic> json) {
    clubId =
    json['clubId'] != null ? ClubId.fromJson(json['clubId']) : null;
    registeredPlayers =
        (json['registeredPlayers'] as List?)?.cast<String>();
  }
}

class ClubId {
  String? id;
  String? clubName;

  ClubId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    clubName = json['clubName'];
  }
}

class Sponsors {
  String? name;
  CategoryId? categoryId;
  String? logo;

  Sponsors.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    categoryId = json['categoryId'] != null
        ? CategoryId.fromJson(json['categoryId'])
        : null;
    logo = json['logo'];
  }
}
class CategoryId {
  String? id;
  String? name;

  CategoryId.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    name = json['name'];
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