class GetCustomerDataByPhoneNumberModel {
  final int? status;
  final Result? result;
  final String? message;

  GetCustomerDataByPhoneNumberModel({this.status, this.result, this.message});

  factory GetCustomerDataByPhoneNumberModel.fromJson(Map<String, dynamic> json) {
    return GetCustomerDataByPhoneNumberModel(
      status: json['status'],
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
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
  final String? id;
  final String? countryCode;
  final int? phoneNumber;
  final String? name;
  final String? lastName;
  final String? category;
  final String? gender;
  final bool? isActive;
  final bool? isDeleted;
  final String? role;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Result({
    this.location,
    this.id,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.category,
    this.gender,
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
      id: json['_id'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      lastName: json['lastName'],
      category: json['category'],
      gender: json['gender'],
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
      '_id': id,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'name': name,
      'lastName': lastName,
      'category': category,
      'gender': gender,
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