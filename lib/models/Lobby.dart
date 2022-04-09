import 'package:cloud_firestore/cloud_firestore.dart';

import 'ActivitoFirestoreModel.dart';
import 'Place.dart';

///in firestore each Lobby has a collection of users (LobbyUser) and a collection of individual fields that need to be listened to
class Lobby extends ActivitoFirestoreModel {
  static final openStage = 'open',
      findingPlaces = 'finding places',
      votingStage = 'voting',
      finalVotesStage = 'final votes',
      //countingVotes = 'counting votes' implemented without updating the lobby stage, after the final votes countdown ends
      finalStage = 'done';

  late String id;

  ///"food" or "other"
  late String lobbyType;

  ///open: waiting for users to join, voting: starts when leader presses "start" ends when all initial votes are in, final votes: users can votes until timer is done, done: the session has ended client should show FinalResultsScreen
  late String lobbyStage;

  late String lobbyCode;

  late DateTime? startCountDownTime;
  List<Place>? placeRecommendations; //top 3 places
  late num numberOfUsers;
  late num? winningPlaceIndex;

  Lobby(this.lobbyCode, this.lobbyType);

  Lobby.fromJson(Map<String, dynamic> json) {
    this.id = validateJsonField(json["id"]);
    this.lobbyType = validateJsonField(json['lobbyType']);
    this.lobbyCode = validateJsonField(json['lobbyCode']);
    this.lobbyStage = validateJsonField(json['lobbyStage']);
    this.numberOfUsers = validateJsonField(json["numberOfUsers"]);
    Timestamp? timestamp = validateJsonField(json['startCountDownTime']);
    this.startCountDownTime = timestamp == null ? null : timestamp.toDate();
    this.winningPlaceIndex = validateJsonField(json['winningPlaceIndex']);

    if (validateJsonField(json["placeRecommendations"] != null)) {
      this.placeRecommendations = [];
      List places =
          List<dynamic>.from(validateJsonField(json["placeRecommendations"]));
      places.forEach((value) {
        this.placeRecommendations!.add(Place.fromJson(value));
      });
    }
  }

  Map<String, Object?> toJson() => {
        'id': id,
        "lobbyCode": lobbyCode,
        "lobbyType": lobbyType,
        "lobbyStage": lobbyStage,
        'startCountDownTime': startCountDownTime,
        "placeRecommendations": placeRecommendations,
        'numberOfUsers': numberOfUsers,
        'winningPlaceIndex': winningPlaceIndex,
      };
}
