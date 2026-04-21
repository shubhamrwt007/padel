class GetIptTournamentStreamUrlModel {
  bool? success;

  GetIptTournamentStreamUrlModel({
    this.success,
  });

  factory GetIptTournamentStreamUrlModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentStreamUrlModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
    };
  }
}
