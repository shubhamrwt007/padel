class GetScheduleDatesIptTournamentModel {
  final bool? success;

  GetScheduleDatesIptTournamentModel({this.success});

  factory GetScheduleDatesIptTournamentModel.fromJson(Map<String, dynamic> json) {
    return GetScheduleDatesIptTournamentModel(
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
    };
  }
}