class GetIptTournamentPollResultsModel {
  bool? success;

  GetIptTournamentPollResultsModel({this.success,});

  factory GetIptTournamentPollResultsModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentPollResultsModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
    };
  }
}