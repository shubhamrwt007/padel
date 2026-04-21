class GetIptTournamentSponsorsModel {
  bool? success;

  GetIptTournamentSponsorsModel({this.success});

  factory GetIptTournamentSponsorsModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentSponsorsModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
  };
}