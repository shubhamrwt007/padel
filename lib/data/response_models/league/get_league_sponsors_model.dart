class GetLeagueSponsorsModel {
  bool? success;
  Data? data;

  GetLeagueSponsorsModel({this.success, this.data});

  factory GetLeagueSponsorsModel.fromJson(Map<String, dynamic> json) {
    return GetLeagueSponsorsModel(
      success: json['success'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data?.toJson(),
  };
}

class Data {
  String? leagueName;
  String? mobileBanner;
  TitleSponsor? titleSponsor;
  List<Sponsors>? sponsors;

  Data({
    this.leagueName,
    this.mobileBanner,
    this.titleSponsor,
    this.sponsors,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      leagueName: json['leagueName'],
      mobileBanner: json['mobileBanner'],
      titleSponsor: json['titleSponsor'] != null
          ? TitleSponsor.fromJson(json['titleSponsor'])
          : null,
      sponsors: (json['sponsors'] as List?)
          ?.map((e) => Sponsors.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'leagueName': leagueName,
    'mobileBanner': mobileBanner,
    'titleSponsor': titleSponsor?.toJson(),
    'sponsors': sponsors?.map((e) => e.toJson()).toList(),
  };
}

class TitleSponsor {
  String? name;
  String? categoryId;
  String? logo;
  String? titleSponsorBanner;

  TitleSponsor({this.name, this.categoryId, this.logo,this.titleSponsorBanner});

  factory TitleSponsor.fromJson(Map<String, dynamic> json) {
    return TitleSponsor(
      name: json['name'],
      categoryId: json['categoryId'],
      logo: json['logo'],
      titleSponsorBanner: json['titleSponsorBanner'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'categoryId': categoryId,
    'logo': logo,
  };
}

class Sponsors {
  String? name;
  CategoryId? categoryId;
  String? id;
  String? logo;
  String? url;

  Sponsors({this.name, this.categoryId, this.id, this.url,this.logo});

  factory Sponsors.fromJson(Map<String, dynamic> json) {
    return Sponsors(
      name: json['name'],
      url: json['url'],
      categoryId: json['categoryId'] != null
          ? CategoryId.fromJson(json['categoryId'])
          : null,
      id: json['_id'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'categoryId': categoryId?.toJson(),
    '_id': id,
    'logo': logo,
  };
}

class CategoryId {
  String? id;
  String? name;

  CategoryId({this.id, this.name});

  factory CategoryId.fromJson(Map<String, dynamic> json) {
    return CategoryId(
      id: json['_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
  };
}