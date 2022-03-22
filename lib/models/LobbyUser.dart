import 'package:activito/models/ActivitoFirestoreModel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/AuthService.dart';
import 'UserLocation.dart';

class LobbyUser extends ActivitoFirestoreModel {
  late String id;
  String accountUserId = "";
  late String name;
  UserLocation userLocation = UserLocation(latitude: 1.1, longitude: 1.1);
  bool isLeader = false;
  late int userNum;

  static List<double> colorOptions = [ //this is the order of the colors
    BitmapDescriptor.hueAzure,
    BitmapDescriptor.hueYellow,
    BitmapDescriptor.hueBlue,
    BitmapDescriptor.hueRose,
    BitmapDescriptor.hueCyan,
    BitmapDescriptor.hueMagenta,
    BitmapDescriptor.hueRed,
    BitmapDescriptor.hueGreen,
    BitmapDescriptor.hueViolet,
    BitmapDescriptor.hueOrange,
  ];

  LobbyUser({required this.name, bool isLeader = false}) {
    if (AuthService.currentUser != null)
      this.accountUserId = AuthService.currentUser!.uid;
    id = Uuid().v4();
    this.isLeader = isLeader;
    this.userNum = -1;
  }

  LobbyUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountUserId = json['activitoUserId'];
    name = json['name'];
    userLocation = UserLocation.fromJson(json['userLocation']);
    isLeader = json['isLeader'];
    userNum = validateJsonField(json['userNum']);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'activitoUserId': accountUserId,
        'name': name,
        'userLocation': userLocation.toJson(),
        'isLeader': isLeader,
        'userNum': userNum
      };

  double getColor() {
    return colorOptions[userNum];
  }
}
