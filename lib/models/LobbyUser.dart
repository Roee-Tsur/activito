import 'package:activito/services/AuthService.dart';
import 'package:uuid/uuid.dart';

import 'UserLocation.dart';

class LobbyUser {
  late String id;
  String activitoUserId = "";
  late String name;
  UserLocation userLocation = UserLocation(latitude: 1.1, longitude: 1.1);
  bool isLeader = false;

  LobbyUser({required this.name, bool isLeader = false}) {
    if (AuthService.currentUser != null)
      this.activitoUserId = AuthService.getCurrentUserId();
    id = Uuid().v4();
    this.isLeader = isLeader;
  }

  LobbyUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    activitoUserId = json['activitoUserId'];
    name = json['name'];
    userLocation = UserLocation.fromJson(json['userLocation']);
    isLeader = json['isLeader'];
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'activitoUserId': activitoUserId,
        'name': name,
        'userLocation': userLocation.toJson(),
        'isLeader': isLeader
      };

}
