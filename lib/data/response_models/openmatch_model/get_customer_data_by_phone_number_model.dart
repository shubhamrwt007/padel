class GetCustomerDataByPhoneNumberModel {
  final int? status;
  final Result? result;
  final List<Result>? results;
  final String? message;

  GetCustomerDataByPhoneNumberModel({this.status, this.result, this.results, this.message});

  factory GetCustomerDataByPhoneNumberModel.fromJson(Map<String, dynamic> json) {
    return GetCustomerDataByPhoneNumberModel(
      status: json['status'],
      result: json['result'] != null && json['result'] is Map
          ? Result.fromJson(json['result'])
          : null,
      results: json['result'] != null && json['result'] is List
          ? (json['result'] as List).map((e) => Result.fromJson(e)).toList()
          : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'result': result?.toJson(),
      'message': message,
    };
  }
}

class Result {
  final Location? location;
  final String? sId;
  final String? countryCode;
  final dynamic phoneNumber;
  final String? name;
  final String? lastName;
  final String? category;
  final String? gender;
  final String? email;
  final String? level;
  final bool? isActive;
  final bool? isDeleted;
  final String? role;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Result({
    this.location,
    this.sId,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.category,
    this.gender,
    this.email,
    this.level,
    this.isActive,
    this.isDeleted,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      sId: json['_id'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      lastName: json['lastName'],
      category: json['category'],
      gender: json['gender'],
      email: json['email'],
      level: json['level'],
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      role: json['role'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location?.toJson(),
      '_id': sId,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'name': name,
      'lastName': lastName,
      'category': category,
      'gender': gender,
      'email': email,
      'level': level,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class Location {
  final List<double>? coordinates;

  Location({this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'].map((x) => x.toDouble()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
    };
  }
}