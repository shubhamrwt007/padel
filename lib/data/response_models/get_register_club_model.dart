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

    data = json['data'] != null
        ? GetRegisterClubData.fromJson(json['data'])
        : null;

    reviewData = json['reviewData'] != null
        ? ReviewData.fromJson(json['reviewData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      if (reviewData != null) 'reviewData': reviewData!.toJson(),
    };
  }
}

class GetRegisterClubData {
  String? sId;
  List<String>? courtImage;
  List<String>? features;
  String? clubName;
  String? description;
  dynamic openingHours;
  dynamic openingDays;
  List<BusinessHours>? businessHours;
  dynamic ownerPhoneNumber;
  ClubLocation? location;

  GetRegisterClubData({
    this.sId,
    this.courtImage,
    this.features,
    this.clubName,
    this.description,
    this.openingHours,
    this.openingDays,
    this.businessHours,
    this.ownerPhoneNumber,
    this.location,
  });

  GetRegisterClubData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];

    courtImage = (json['courtImage'] as List?)
        ?.map((e) => e.toString())
        .toList();

    features = (json['features'] as List?)
        ?.map((e) => e.toString())
        .toList();

    clubName = json['clubName'];
    description = json['description'];

    openingHours = json['openingHours'];
    openingDays = json['openingDays'];
    ownerPhoneNumber = json['ownerPhoneNumber'];

    businessHours = (json['businessHours'] as List?)
        ?.map((e) => BusinessHours.fromJson(e))
        .toList();

    location = json['location'] != null
        ? ClubLocation.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'courtImage': courtImage,
      'features': features,
      'clubName': clubName,
      'description': description,
      'openingHours': openingHours,
      'openingDays': openingDays,
      'ownerPhoneNumber': ownerPhoneNumber,
      'businessHours': businessHours?.map((e) => e.toJson()).toList(),
      if (location != null) 'location': location!.toJson(),
    };
  }
}

class BusinessHours {
  String? day;
  String? time;

  BusinessHours({
    this.day,
    this.time,
  });

  BusinessHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'time': time,
    };
  }
}

class ClubLocation {
  String? city;
  String? address;
  String? zipCode;
  String? state;
  String? stateId;
  List<String>? courtType;
  bool? status;
  List<String>? categories;
  String? sId;

  ClubLocation({
    this.city,
    this.address,
    this.zipCode,
    this.state,
    this.stateId,
    this.courtType,
    this.status,
    this.categories,
    this.sId,
  });

  ClubLocation.fromJson(Map<String, dynamic> json) {
    city = json['city'];
    address = json['address'];
    zipCode = json['zipCode'];
    state = json['state'];
    stateId = json['stateId'];

    courtType = (json['courtType'] as List?)
        ?.map((e) => e.toString())
        .toList();

    status = json['status'];

    categories = (json['categories'] as List?)
        ?.map((e) => e.toString())
        .toList();

    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'address': address,
      'zipCode': zipCode,
      'state': state,
      'stateId': stateId,
      'courtType': courtType,
      'status': status,
      'categories': categories,
      '_id': sId,
    };
  }
}

class ReviewData {
  num? averageRating;
  int? totalReviews;

  ReviewData({
    this.averageRating,
    this.totalReviews,
  });

  ReviewData.fromJson(Map<String, dynamic> json) {
    averageRating = json['averageRating'];
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}