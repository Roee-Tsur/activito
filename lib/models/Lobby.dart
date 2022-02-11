import 'ActivitoFirestoreModel.dart';
import 'Place.dart';

///in firestore each Lobby has a collection of users (LobbyUser)
class Lobby extends ActivitoFirestoreModel {
  late String id;

  ///"food" or "other"
  late String lobbyType;
  late String lobbyCode;
  late bool isStarted;
  late Map<String, Place>? placeRecommendations;

  ///options: cheapest, bestRating

  Lobby(this.lobbyCode, this.lobbyType);

  Lobby.fromJson(Map<String, dynamic> json) {
    this.id = validateJsonField(json["id"]);
    this.lobbyType = validateJsonField(json['lobbyType']);
    this.lobbyCode = validateJsonField(json['lobbyCode']);
    this.isStarted = validateJsonField(json['isStarted']);

    this.placeRecommendations = {};
    Map places = Map<String, dynamic>.from(
        validateJsonField(json["placeRecommendations"]));
    places.forEach((key, value) {
      this.placeRecommendations![key] = Place.fromJson(value);
    });
  }

  Map<String, Object?> toJson() => {
        'id': id,
        "lobbyCode": lobbyCode,
        "lobbyType": lobbyType,
        "isStarted": isStarted,
        "placeRecommendations": placeRecommendations
      };
}
