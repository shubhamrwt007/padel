class DeleteBulkSlotHistoryModel {
  final bool? success;
  final int? deletedCount;
  final String? message;

  const DeleteBulkSlotHistoryModel({
    this.success,
    this.deletedCount,
    this.message,
  });

  factory DeleteBulkSlotHistoryModel.fromJson(Map<String, dynamic> json) {
    return DeleteBulkSlotHistoryModel(
      success: json['success'],
      deletedCount: json['deletedCount'],
      message: json['message'],
    );
  }
}
