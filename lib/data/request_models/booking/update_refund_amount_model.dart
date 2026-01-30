class UpdateRefundAmountModel {
  final int? status;
  final String? message;
  final RefundDetails? refundDetails;

  const UpdateRefundAmountModel({
    this.status,
    this.message,
    this.refundDetails,
  });

  factory UpdateRefundAmountModel.fromJson(Map<String, dynamic> json) {
    return UpdateRefundAmountModel(
      status: json['status'],
      message: json['message'],
      refundDetails: json['refundDetails'] != null
          ? RefundDetails.fromJson(json['refundDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    if (refundDetails != null) 'refundDetails': refundDetails!.toJson(),
  };
}

class RefundDetails {
  final int? refundAmount;
  final int? walletBalance;

  const RefundDetails({
    this.refundAmount,
    this.walletBalance,
  });

  factory RefundDetails.fromJson(Map<String, dynamic> json) {
    return RefundDetails(
      refundAmount: json['refundAmount'],
      walletBalance: json['walletBalance'],
    );
  }

  Map<String, dynamic> toJson() => {
    'refundAmount': refundAmount,
    'walletBalance': walletBalance,
  };
}
