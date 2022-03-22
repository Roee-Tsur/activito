import 'package:activito/models/ActivitoFirestoreModel.dart';

import 'UserLocation.dart';

class Place extends ActivitoFirestoreModel {
  late String name;
  late String address;
  late String? phoneNumber;
  late String? website;
  late num? rating;
  late num? userRatingsTotal;
  late num? priceLevel;
  late UserLocation? location;
  late List<String>? photos;
  late String? placeId;

  Place.fromJson(Map<String, dynamic> json) {
    this.placeId = validateJsonField(json['placeId']);
    this.name = validateJsonField(json['name']);
    this.address = validateJsonField(json['address']);
    this.phoneNumber = validateJsonField(json['phoneNumber']);
    this.website = validateJsonField(json['website']);
    this.priceLevel = validateJsonField(json['priceLevel']);
    this.rating = validateJsonField(json['rating']);
    this.userRatingsTotal = validateJsonField(json['userRatingsTotal']);
    this.location = validateJsonField(
        UserLocation.fromJson(Map<String, dynamic>.from(json['location'])));

    this.photos = [];
    List photos = List<String>.from(validateJsonField(json["photos"]));
    photos.forEach((value) {
      this.photos!.add(value);
    });
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'address': address,
        'phoneNumber': phoneNumber,
        'website': website,
        'priceLevel': priceLevel,
        'rating': rating,
        'userRatingsTotal': userRatingsTotal,
        'location': location!.toJson(),
        'photos': photos,
        'placeId': placeId
      };
}
