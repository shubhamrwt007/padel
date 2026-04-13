class GetScheduleDatesModel {
  final bool? success;
  final List<String>? data;

  GetScheduleDatesModel({this.success, this.data});

  factory GetScheduleDatesModel.fromJson(Map<String, dynamic> json) {
    return GetScheduleDatesModel(
      success: json['success'],
      data: (json['data'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
    };
  }
}