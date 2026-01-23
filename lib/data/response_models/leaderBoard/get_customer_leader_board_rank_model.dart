class GetCustomerLeaderBoardRankModel {
  final bool success;
  final int? rank;

  const GetCustomerLeaderBoardRankModel({
    required this.success,
    required this.rank,
  });

  factory GetCustomerLeaderBoardRankModel.fromJson(Map<String, dynamic> json) {
    return GetCustomerLeaderBoardRankModel(
      success: json['success'] as bool? ?? false,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'rank': rank,
    };
  }
}
