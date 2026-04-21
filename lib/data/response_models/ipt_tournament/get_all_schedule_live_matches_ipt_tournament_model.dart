class GetAllScheduleLiveMatchesIptTournamentModel {
  bool? success;


  GetAllScheduleLiveMatchesIptTournamentModel({this.success,});

  factory GetAllScheduleLiveMatchesIptTournamentModel.fromJson(Map<String, dynamic> json) {
    return GetAllScheduleLiveMatchesIptTournamentModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
  };
}
