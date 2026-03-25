class GetRegisterClubModel {
  bool? success;
  String? message;
  GetRegisterClubData? data;
  ReviewData? reviewData;

  GetRegisterClubModel({
    this.success,
    this.message,
    this.data,
    this.reviewData,
  });

  GetRegisterClubModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? GetRegisterClubData.fromJson(json['data']) : null;
    reviewData = json['reviewData'] != null
        ? ReviewData.fromJson(json['reviewData'])
        : null;
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (data != null) 'data': data!.toJson(),
    if (reviewData != null) 'reviewData': reviewData!.toJson(),
  };
}

class GetRegisterClubData {
  Location? location;
  String? sId;
  String? clubName;
  String? ownerId;
  int? iV;
  String? address;
  List<BusinessHours>? businessHours;
  String? city;
  int? courtCount;
  List<String>? courtImage;
  List<String>? courtName;
  List<String>? courtType;
  String? createdAt;
  List<String>? features;
  bool? isActive;
  bool? isDeleted;
  bool? isFeatured;
  bool? isVerified;
  String? state;
  String? updatedAt;
  String? zipCode;
  String? description;
  dynamic ownerPhoneNumber;

  GetRegisterClubData({
    this.location,
    this.sId,
    this.clubName,
    this.ownerId,
    this.iV,
    this.address,
    this.businessHours,
    this.city,
    this.courtCount,
    this.courtImage,
    this.courtName,
    this.courtType,
    this.createdAt,
    this.features,
    this.isActive,
    this.isDeleted,
    this.isFeatured,
    this.isVerified,
    this.state,
    this.updatedAt,
    this.zipCode,
    this.description,
    this.ownerPhoneNumber,
  });

  GetRegisterClubData.fromJson(Map<String, dynamic> json) {
    location =
    json['location'] != null ? Location.fromJson(json['location']) : null;

    sId = json['_id'];
    clubName = json['clubName'];
    ownerId = json['ownerId'];
    iV = json['__v'];
    address = json['address'];

    // Safe loop
    if (json['businessHours'] != null) {
      businessHours = (json['businessHours'] as List)
          .map((e) => BusinessHours.fromJson(e))
          .toList();
    }

    city = json['city'];
    courtCount = json['courtCount'];

    courtImage = (json['courtImage'] as List?)?.map((e) => e.toString()).toList();
    courtName = (json['courtName'] as List?)?.map((e) => e.toString()).toList();
    courtType = (json['courtType'] as List?)?.map((e) => e.toString()).toList();

    createdAt = json['createdAt'];
    features = (json['features'] as List?)?.map((e) => e.toString()).toList();

    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    isFeatured = json['isFeatured'];
    isVerified = json['isVerified'];

    state = json['state'];
    updatedAt = json['updatedAt'];
    zipCode = json['zipCode'];
    description = json['description'];
    ownerPhoneNumber = json['ownerPhoneNumber'];
  }

  Map<String, dynamic> toJson() => {
    if (location != null) 'location': location!.toJson(),
    '_id': sId,
    'clubName': clubName,
    'ownerId': ownerId,
    '__v': iV,
    'address': address,
    if (businessHours != null)
      'businessHours': businessHours!.map((e) => e.toJson()).toList(),
    'city': city,
    'courtCount': courtCount,
    'courtImage': courtImage,
    'courtName': courtName,
    'courtType': courtType,
    'createdAt': createdAt,
    'features': features,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'isFeatured': isFeatured,
    'isVerified': isVerified,
    'state': state,
    'updatedAt': updatedAt,
    'zipCode': zipCode,
    'description': description,
    'ownerPhoneNumber': ownerPhoneNumber,
  };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = (json['coordinates'] as List?)
        ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}

class BusinessHours {
  String? time;
  String? day;
  String? sId;

  BusinessHours({this.time, this.day, this.sId});

  BusinessHours.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    day = json['day'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'day': day,
    '_id': sId,
  };
}

class ReviewData {
  int? averageRating;
  int? totalReviews;

  ReviewData({this.averageRating, this.totalReviews});

  ReviewData.fromJson(Map<String, dynamic> json) {
    averageRating = json['averageRating'];
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() => {
    'averageRating': averageRating,
    'totalReviews': totalReviews,
  };
}
