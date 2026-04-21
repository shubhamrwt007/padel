class GetIptTournamentMatchDetailsModel {
  bool? success;
  GetIptTournamentMatchDetailsModel({this.success,});

  GetIptTournamentMatchDetailsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
  }
}