class GetWalletModel {
  final String? id;
  final String? userId;
  final int? balance;
  final int? totalDebitedBalance;
  final bool? isActive;

  const GetWalletModel({
    this.id,
    this.userId,
    this.balance,
    this.totalDebitedBalance,
    this.isActive,
  });

  factory GetWalletModel.fromJson(Map<String, dynamic> json) {
    return GetWalletModel(
      id: json['_id'],
      userId: json['userId'],
      balance: json['balance'] != null
          ? (json['balance'] as num).toInt()
          : null,
      totalDebitedBalance: json['totalDebitedBalance'] != null
          ? (json['totalDebitedBalance'] as num).toInt()
          : null,
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'balance': balance,
    'totalDebitedBalance': totalDebitedBalance,
    'isActive': isActive,
  };
}
