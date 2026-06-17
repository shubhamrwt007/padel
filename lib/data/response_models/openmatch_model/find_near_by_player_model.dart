class FindNearByPlayerModel {
  final int? status;
  final String? message;
  final List<Player>? players;
  final Pagination? pagination;

  const FindNearByPlayerModel({
    this.status,
    this.message,
    this.players,
    this.pagination,
  });

  factory FindNearByPlayerModel.fromJson(Map<String, dynamic> json) {
    return FindNearByPlayerModel(
      status: json['status'],
      message: json['message'],
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null 
          ? Pagination.fromJson(json['pagination']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'players': players?.map((e) => e.toJson()).toList(),
    'pagination': pagination?.toJson(),
  };
  
  // Helper getters for backward compatibility
  int? get totalPages => pagination?.totalPages;
  int? get currentPage => pagination?.currentPage;
  int? get totalPlayers => pagination?.totalItems;
}

class Pagination {
  final int? totalItems;
  final int? totalPages;
  final int? currentPage;
  final int? limit;
  final bool? hasNextPage;
  final bool? hasPrevPage;
  final int? nextPage;
  final int? prevPage;

  const Pagination({
    this.totalItems,
    this.totalPages,
    this.currentPage,
    this.limit,
    this.hasNextPage,
    this.hasPrevPage,
    this.nextPage,
    this.prevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['totalItems'],
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      limit: json['limit'],
      hasNextPage: json['hasNextPage'],
      hasPrevPage: json['hasPrevPage'],
      nextPage: json['nextPage'],
      prevPage: json['prevPage'],
    );
  }

  Map<String, dynamic> toJson() => {
    'totalItems': totalItems,
    'totalPages': totalPages,
    'currentPage': currentPage,
    'limit': limit,
    'hasNextPage': hasNextPage,
    'hasPrevPage': hasPrevPage,
    'nextPage': nextPage,
    'prevPage': prevPage,
  };
}

class Player {
  final String? id;
  final String? name;
  final String? city;
  final String? cityName;
  final String? level;
  final String? profilePic;
  final int? totalMatchesPlayed;
  final bool? hasPendingRequest;
  final dynamic xpPoints;

  const Player({
    this.id,
    this.name,
    this.city,
    this.cityName,
    this.level,
    this.profilePic,
    this.totalMatchesPlayed,
    this.hasPendingRequest,
    this.xpPoints,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      city: json['city']?.toString(),
      cityName: json['cityName']?.toString(),
      level: json['level']?.toString(),
      profilePic: json['profilePic']?.toString(),
      totalMatchesPlayed: json['totalMatchesPlayed'] is int 
          ? json['totalMatchesPlayed'] 
          : int.tryParse(json['totalMatchesPlayed']?.toString() ?? '0') ?? 0,
      hasPendingRequest: json['hasPendingRequest'] == true,
      xpPoints: json['xpPoints'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'city': city,
    'cityName': cityName,
    'playerLevel': level,
    'profilePic': profilePic,
    'totalMatchesPlayed': totalMatchesPlayed,
    'hasPendingRequest': hasPendingRequest,
    'xpPoints': xpPoints,
  };
}
