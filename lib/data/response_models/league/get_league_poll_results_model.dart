class GetLeaguePollResultsModel {
  bool? success;
  Data? data;

  GetLeaguePollResultsModel({this.success, this.data});

  factory GetLeaguePollResultsModel.fromJson(Map<String, dynamic> json) {
    return GetLeaguePollResultsModel(
      success: json['success'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class Data {
  Poll? poll;
  int? totalVotes;
  List<Clubs>? clubs;

  Data({this.poll, this.totalVotes, this.clubs});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
      totalVotes: json['totalVotes'],
      clubs: (json['clubs'] as List?)
          ?.map((e) => Clubs.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poll': poll?.toJson(),
      'totalVotes': totalVotes,
      'clubs': clubs?.map((e) => e.toJson()).toList(),
    };
  }
}

class Poll {
  String? id;
  String? question;

  Poll({this.id, this.question});

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['_id'],
      question: json['question'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
    };
  }
}

class Clubs {
  String? clubName;
  String? logo;
  String? clubId;
  int? votes;
  dynamic? percentage;
  String? rgbColor;

  Clubs({
    this.clubName,
    this.logo,
    this.clubId,
    this.votes,
    this.percentage,
    this.rgbColor,
  });

  factory Clubs.fromJson(Map<String, dynamic> json) {
    return Clubs(
      clubName: json['clubName'],
      logo: json['logo'],
      clubId: json['clubId'],
      votes: json['votes'],
      percentage: json['percentage'],
      rgbColor: json['rgbColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clubName': clubName,
      'logo': logo,
      'clubId': clubId,
      'votes': votes,
      'percentage': percentage,
      'rgbColor': rgbColor,
    };
  }
}