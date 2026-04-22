class GetScheduleDatesIptTournamentModel {
  final bool? success;
  final List<String>? data;
  final List<String>? categories;

  GetScheduleDatesIptTournamentModel({this.success, this.data, this.categories});

  factory GetScheduleDatesIptTournamentModel.fromJson(Map<String, dynamic> json) {
    final List<String> dates = [];
    final Set<String> categorySet = {};

    if (json['data'] is List) {
      for (var item in json['data']) {
        if (item is Map<String, dynamic>) {
          if (item['date'] != null) {
            final dateStr = item['date'].toString();
            if (!dates.contains(dateStr)) {
              dates.add(dateStr);
            }
          }
          if (item['categoryType'] != null) {
            categorySet.add(item['categoryType'].toString());
          }
        }
      }
    }

    return GetScheduleDatesIptTournamentModel(
      success: json['success'],
      data: dates,
      categories: categorySet.toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'categories': categories,
    };
  }
}