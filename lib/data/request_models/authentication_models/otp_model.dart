class OTPModel {
  String? status;
  String? message;
  String? response;
  dynamic? otp;

  OTPModel({this.status, this.message, this.response,this.otp});

  OTPModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    otp = json['otp'];
    message = json['message'];
    response = json['response'];
  }
}
