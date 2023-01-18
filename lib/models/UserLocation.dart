import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserLocation {
  late double latitude;
  late double longitude;

  UserLocation({required this.latitude, required this.longitude});

  UserLocation.defaultValues() {
    this.longitude = 1.1;
    this.latitude = 1.1;
  }

  ///LocationData or LatLng
  UserLocation.fromDynamic(dynamic location) {
    this.latitude = location.latitude!;
    this.longitude = location.longitude!;
  }

  UserLocation.fromJson(Map<String, dynamic> json) {
    this.latitude = json['latitude'];
    this.longitude = json['longitude'];
  }

  Map<String, Object?> toJson() =>
      {'latitude': latitude, 'longitude': longitude};

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  @override
  String toString() => "($latitude,$longitude)";

  String toUrlParameter() {
    return latitude.toString() + '-' + longitude.toString();
  }
}
