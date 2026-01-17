class GetAllSlotPricesOfCourtModel {
  final bool? success;
  final int? count;
  final bool? hasThirtyMinPrice;
  final List<SlotPrice>? data;

  const GetAllSlotPricesOfCourtModel({
    this.success,
    this.count,
    this.data,
    this.hasThirtyMinPrice,
  });

  factory GetAllSlotPricesOfCourtModel.fromJson(Map<String, dynamic> json) =>
      GetAllSlotPricesOfCourtModel(
        success: json['success'],
        count: json['count'],
        hasThirtyMinPrice: json['hasThirtyMinPrice'],
        data: (json['data'] as List?)
            ?.map((e) => SlotPrice.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'success': success,
    'count': count,
    'hasThirtyMinPrice': hasThirtyMinPrice,
    'data': data?.map((e) => e.toJson()).toList(),
  };
}

class SlotPrice {
  final String? id;
  final int? duration;
  final String? day;
  final int? price;
  final String? slotTime;
  final String? timePeriod;
  final String? registerClubId;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  const SlotPrice({
    this.id,
    this.duration,
    this.day,
    this.price,
    this.slotTime,
    this.timePeriod,
    this.registerClubId,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  factory SlotPrice.fromJson(Map<String, dynamic> json) => SlotPrice(
    id: json['_id'],
    duration: json['duration'],
    day: json['day'],
    price: json['price'],
    slotTime: json['slotTime'],
    timePeriod: json['timePeriod'],
    registerClubId: json['register_club_id'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    version: json['__v'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'duration': duration,
    'day': day,
    'price': price,
    'slotTime': slotTime,
    'timePeriod': timePeriod,
    'register_club_id': registerClubId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': version,
  };
}
