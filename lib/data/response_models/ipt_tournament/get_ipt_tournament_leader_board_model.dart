class GetIptTournamentLeaderBoardModel {
  final bool? success;

  GetIptTournamentLeaderBoardModel({this.success,});

  factory GetIptTournamentLeaderBoardModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentLeaderBoardModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
  };
}
