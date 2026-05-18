class CastLeagueVoteModel {
  bool? success;
  String? message;
  Data? data;

  CastLeagueVoteModel({this.success, this.message, this.data});

  factory CastLeagueVoteModel.fromJson(Map<String, dynamic> json) {
    return CastLeagueVoteModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class Data {
  String? pollId;
  String? clubId;
  String? clubName;
  String? deviceId;
  String? userId;
  String? previousClub;

  Data({
    this.pollId,
    this.clubId,
    this.clubName,
    this.deviceId,
    this.userId,
    this.previousClub,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      pollId: json['pollId'],
      clubId: json['clubId'],
      clubName: json['clubName'],
      deviceId: json['deviceId'],
      userId: json['userId'],
      previousClub: json['previousClub'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      'clubId': clubId,
      'clubName': clubName,
      'deviceId': deviceId,
      'userId': userId,
      'previousClub': previousClub,
    };
  }
}