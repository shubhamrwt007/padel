class LiveWalletAddBalanceModel {
  String? orderId;
  int? amount;
  String? currency;

  LiveWalletAddBalanceModel({this.orderId, this.amount, this.currency});

  LiveWalletAddBalanceModel.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    amount = json['amount'];
    currency = json['currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['orderId'] = this.orderId;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    return data;
  }
}
