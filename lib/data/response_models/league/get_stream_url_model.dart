class GetStreamUrlModel {
  bool? success;
  GetStreamUrlData? data;

  GetStreamUrlModel({
    this.success,
    this.data,
  });

  factory GetStreamUrlModel.fromJson(Map<String, dynamic> json) {
    return GetStreamUrlModel(
      success: json['success'],
      data: json['data'] != null ? GetStreamUrlData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class GetStreamUrlData {
  String? id;
  String? matchStatus;
  String? matchId;
  String? scoreboardUrl;
  String? streamKey;

  GetStreamUrlData({
    this.id,
    this.matchStatus,
    this.matchId,
    this.scoreboardUrl,
    this.streamKey,
  });

  factory GetStreamUrlData.fromJson(Map<String, dynamic> json) {
    return GetStreamUrlData(
      id: json['_id'],
      matchStatus: json['matchStatus'],
      matchId: json['matchId'],
      scoreboardUrl: json['scoreboardUrl'],
      streamKey: json['streamKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matchStatus': matchStatus,
      'matchId': matchId,
      'scoreboardUrl': scoreboardUrl,
      'streamKey': streamKey,
    };
  }
}