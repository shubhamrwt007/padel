class FindNearByPlayerModel {
  final int? status;
  final String? message;
  final List<Player>? players;

  const FindNearByPlayerModel({
    this.status,
    this.message,
    this.players,
  });

  factory FindNearByPlayerModel.fromJson(Map<String, dynamic> json) {
    return FindNearByPlayerModel(
      status: json['status'],
      message: json['message'],
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'players': players?.map((e) => e.toJson()).toList(),
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
  final dynamic? xpPoints;

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
      id: json['_id'],
      name: json['name'],
      city: json['city'],
      cityName: json['cityName'],
      level: json['playerLevel'],
      profilePic: json['profilePic'],
      totalMatchesPlayed: json['totalMatchesPlayed'],
      hasPendingRequest: json['hasPendingRequest'],
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
