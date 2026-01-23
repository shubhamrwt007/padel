class TransactionHistoryModel {
  final int? status;
  final String? message;
  final List<Transaction>? transactions;
  final int? totalPages;
  final String? currentPage;
  final int? total;

  TransactionHistoryModel({
    this.status,
    this.message,
    this.transactions,
    this.totalPages,
    this.currentPage,
    this.total,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
      transactions: (json['transactions'] as List?)
          ?.map((e) => Transaction.fromJson(e))
          .toList(),
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      total: json['total'],
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'transactions': transactions?.map((e) => e.toJson()).toList(),
    'totalPages': totalPages,
    'currentPage': currentPage,
    'total': total,
    'status': status,
    'message': message,
  };
}

class Transaction {
  final String? id;
  final UserId? userId;
  final String? walletId;
  final int? amount;
  final String? type;
  final String? status;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  Transaction({
    this.id,
    this.userId,
    this.walletId,
    this.amount,
    this.type,
    this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'],
      userId:
      json['userId'] != null ? UserId.fromJson(json['userId']) : null,
      walletId: json['walletId'],
      amount: (json['amount'] as num?)?.toInt(), // ✅ FIX
      type: json['type'],
      status: json['status'],
      description: json['description'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId?.toJson(),
    'walletId': walletId,
    'amount': amount,
    'type': type,
    'status': status,
    'description': description,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class UserId {
  final Location? location;
  final String? id;
  final String? email;
  final String? countryCode;
  final int? phoneNumber;
  final String? name;
  final String? lastName;
  final String? password;
  final String? city;
  final bool? agreeTermsAndCondition;
  final String? category;
  final bool? isActive;
  final bool? isDeleted;
  final String? role;
  final List<String>? fcmTokens;
  final int? totalMatchesPlayed;
  final int? totalWins;
  final int? simpleMatchCount;
  final int? openMatchCount;
  final int? americanMatchCount;
  final int? rank;
  final dynamic? xpPoints;
  final int? currentWinStreak;
  final int? currentLoseStreak;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  UserId({
    this.location,
    this.id,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.name,
    this.lastName,
    this.password,
    this.city,
    this.agreeTermsAndCondition,
    this.category,
    this.isActive,
    this.isDeleted,
    this.role,
    this.fcmTokens,
    this.totalMatchesPlayed,
    this.totalWins,
    this.simpleMatchCount,
    this.openMatchCount,
    this.americanMatchCount,
    this.rank,
    this.xpPoints,
    this.currentWinStreak,
    this.currentLoseStreak,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory UserId.fromJson(Map<String, dynamic> json) {
    return UserId(
      location:
      json['location'] != null ? Location.fromJson(json['location']) : null,
      id: json['_id'],
      email: json['email'],
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      lastName: json['lastName'],
      password: json['password'],
      city: json['city'],
      agreeTermsAndCondition: json['agreeTermsAndCondition'],
      category: json['category'],
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      role: json['role'],
      fcmTokens: (json['fcmTokens'] as List?)?.cast<String>(),
      totalMatchesPlayed: json['totalMatchesPlayed'],
      totalWins: json['totalWins'],
      simpleMatchCount: json['simpleMatchCount'],
      openMatchCount: json['openMatchCount'],
      americanMatchCount: json['americanMatchCount'],
      rank: json['rank'],
      xpPoints: (json['xpPoints'] as num?)?.toDouble(),
      currentWinStreak: json['currentWinStreak'],
      currentLoseStreak: json['currentLoseStreak'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    'location': location?.toJson(),
    '_id': id,
    'email': email,
    'countryCode': countryCode,
    'phoneNumber': phoneNumber,
    'name': name,
    'lastName': lastName,
    'password': password,
    'city': city,
    'agreeTermsAndCondition': agreeTermsAndCondition,
    'category': category,
    'isActive': isActive,
    'isDeleted': isDeleted,
    'role': role,
    'fcmTokens': fcmTokens,
    'totalMatchesPlayed': totalMatchesPlayed,
    'totalWins': totalWins,
    'simpleMatchCount': simpleMatchCount,
    'openMatchCount': openMatchCount,
    'americanMatchCount': americanMatchCount,
    'rank': rank,
    'xpPoints': xpPoints,
    'currentWinStreak': currentWinStreak,
    'currentLoseStreak': currentLoseStreak,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
  };
}

class Location {
  final String? type;
  final List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}
