import 'package:activito/models/ActivitoFirestoreModel.dart';

import 'UserLocation.dart';

class Place extends ActivitoFirestoreModel {
  late String name;
  late String address;
  late String? phoneNumber;
  late String? icon;
  late String? website;
  late num? rating;
  late num? userRatingTotal;
  late num? priceLevel;
  late UserLocation? location;
  late List<String>? photos;

  Place.fromJson(Map<String, dynamic> json) {
    this.name = validateJsonField(json['name']);
    this.address = validateJsonField(json['address']);
    this.phoneNumber = validateJsonField(json['phoneNumber']);
    this.icon = validateJsonField(json['icon']);
    this.website = validateJsonField(json['website']);
    this.priceLevel = validateJsonField(json['priceLevel']);
    this.rating = validateJsonField(json['rating']);
    this.userRatingTotal = validateJsonField(json['userRatingTotal']);
    this.location = validateJsonField(
        UserLocation.fromJson(Map<String, dynamic>.from(json['location'])));

    this.photos = [];
    List photos =
        List<String>.from(validateJsonField(json["photos"]));
    photos.forEach((value) {
      this.photos!.add(value);
    });
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'address': address,
        'phoneNumber': phoneNumber,
        'icon': icon,
        'website': website,
        'priceLevel': priceLevel,
        'rating': rating,
        'userRatingTotal': userRatingTotal,
        'location': location!.toJson(),
        'photos': photos
      };
}
