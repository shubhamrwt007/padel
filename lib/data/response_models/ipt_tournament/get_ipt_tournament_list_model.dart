class GetIptTournamentListModel {
  bool? success;

  GetIptTournamentListModel({this.success,});

  factory GetIptTournamentListModel.fromJson(Map<String, dynamic> json) {
    return GetIptTournamentListModel(
      success: json['success'],
    );
  }
}