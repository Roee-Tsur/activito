import 'dart:io';

import 'package:activito/models/Lobby.dart';
import 'package:activito/models/ActivitoUser.dart';
import 'package:activito/models/LobbySession.dart';
import 'package:activito/models/LobbyUser.dart';
import 'package:activito/models/Message.dart';
import 'package:activito/models/UserLocation.dart';
import 'package:activito/nice_widgets/LobbyPlacesList.dart';
import 'package:activito/screens/LobbyScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/Lobby.dart';
import '../models/Place.dart';
import 'AuthService.dart';

class Server {
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseStorage _storage = FirebaseStorage.instance;
  static FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: "europe-west1");
  static String pathSeparator = Platform.pathSeparator;

  static CollectionReference _usersCollection = _firestore
      .collection("users")
      .withConverter<ActivitoUser>(
          fromFirestore: (snapshot, _) =>
              ActivitoUser.fromJson(snapshot.data()!),
          toFirestore: (activitoUser, _) => activitoUser.toJson());
  static CollectionReference _lobbiesCollection = _firestore
      .collection("lobbies")
      .withConverter<Lobby>(
          fromFirestore: (snapshot, _) => Lobby.fromJson(snapshot.data()!),
          toFirestore: (lobby, _) => lobby.toJson());

  /// calls functions with enteredCode and returns 0 (joined successfully) or 1 (error, didn't join) and a reason(String)
  static Future<LobbySession> joinLobby({
    required String enteredCode,
    required LobbyUser lobbyUser,
  }) async {
    final functionParameters = {
      "enteredCode": enteredCode,
      "lobbyUser": lobbyUser.toJson()
    };
    final resultsData =
        (await _functions.httpsCallable('joinLobby').call(functionParameters))
            .data;
    if (resultsData["requestStatus"] == 0) {
      Fluttertoast.showToast(msg: "joined lobby");
      final lobbyData =
          (await _lobbiesCollection.doc(resultsData["lobbyId"]).get()).data();
      return LobbySession(lobbyData as Lobby);
    } else {
      Fluttertoast.showToast(
          msg: "didn't join lobby: ${resultsData["reason"]}",
          toastLength: Toast.LENGTH_LONG);
      return LobbySession.isNull();
    }
  }

  /// creates lobby and then join it
  static Future<LobbySession> createLobby(
      {required String lobbyType, required LobbyUser lobbyUser}) async {
    final functionParameters = {
      "lobbyType": lobbyType,
    };
    final lobbyCode =
        (await _functions.httpsCallable('createLobby').call(functionParameters))
            .data["lobbyCode"] as String;
    return joinLobby(enteredCode: lobbyCode, lobbyUser: lobbyUser);
  }

  static Future<void> setProfilePic(File newProfilePic) async {
    String serverPicPath = "profilePics/${AuthService.currentUser!.uid}.jpg";
    try {
      _storage.ref(serverPicPath).putFile(newProfilePic);
    } on Exception catch (e) {
      Fluttertoast.showToast(msg: "upload failed");
      print(e);
    }

    AuthService.setProfilePic(
        await _storage.ref(serverPicPath).getDownloadURL());
  }

  // static Future<Image> getCurrentUserProfilePic() async {
  //   String filePath = (await getApplicationDocumentsDirectory()).path +
  //       pathSeparator +
  //       "profilePic.jpg";
  //   File profilePicFile = File(filePath);
  //
  //   if (!(await profilePicFile.exists()))
  //     return Image.asset("assets/defaultProfilePic.jpg");
  //
  //   return Image.file(profilePicFile);
  // }
  //
  // static Future<Image> getUserProfilePic(String userID) async {
  //   //not sure if the directory is correct...
  //   String filePath = (await getTemporaryDirectory()).path +
  //       pathSeparator +
  //       "profilePic-$userID.jpg";
  //   File profilePicFile = File(filePath);
  //   String serverPicPath = "profilePics/$userID.jpg";
  //   await _storage.ref(serverPicPath).writeToFile(profilePicFile);
  //
  //   return Image.file(profilePicFile);
  // }
  //
  // /// this method deletes any existing profile picture. when user retries to load the pic Server will return null and default pic will be shown
  // static Future deleteProfilePic() async {
  //   await _storage
  //       .ref("profilePics/${AuthService.getCurrentUserId()}.jpg")
  //       .delete();
  //   String localProfilePicPath =
  //       (await getApplicationDocumentsDirectory()).path +
  //           pathSeparator +
  //           "profilePic.jpg";
  //   File localProfilePicFile = File(localProfilePicPath);
  //   await localProfilePicFile.delete();
  // }
  //
  // static Future initProfilePic() async {
  //   String filePath = (await getApplicationDocumentsDirectory()).path +
  //       pathSeparator +
  //       "profilePic.jpg";
  //   File profilePicFile = File(filePath);
  //   String serverPicPath = "profilePics/${AuthService.getCurrentUserId()}.jpg";
  //   await _storage.ref(serverPicPath).writeToFile(profilePicFile);
  // }

  static Stream<DocumentSnapshot> getLobbyEventListener(Lobby lobby) =>
      _lobbiesCollection.doc(lobby.id).snapshots();

  static void updateUserLocation(
      Lobby lobby, String thisLobbyUserId, UserLocation userLocation) {
    _getLobbyUsersCollectionRef(lobby)
        .doc(thisLobbyUserId)
        .update({'userLocation': userLocation.toJson()});
  }

  /// return a the users of a lobby mapped by their id
  static Future<Map<String, LobbyUser>> getLobbyUsersMap(Lobby lobby) async {
    Query query = _getLobbyUsersCollectionRef(lobby);
    final data = (await query.get()).docs;
    List<LobbyUser> users =
        List.generate(data.length, (index) => data[index].data() as LobbyUser);
    List<String> ids = List.generate(users.length, (index) => users[index].id);
    return Map.fromIterables(ids, users);
  }

  static Stream<QuerySnapshot<LobbyUser>> getLobbyUsersEventListener(
          Lobby lobby) =>
      _getLobbyUsersCollectionRef(lobby).snapshots();

  static Stream<QuerySnapshot<Message>> getLobbyMessagesEventListener(
          Lobby lobby) =>
      _getMessagesCollectionRef(lobby)
          .orderBy('timestamp', descending: false)
          .snapshots();

  /// adds message to DB and return the message
  static Message sendMessage(
      {required Lobby lobby,
      required LobbyUser sender,
      required String messageValue}) {
    Message message = Message(sender, messageValue);
    _getMessagesCollectionRef(lobby).doc(message.id).set(message);
    return message;
  }

  static CollectionReference<LobbyUser> _getLobbyUsersCollectionRef(
          Lobby lobby) =>
      _lobbiesCollection
          .doc(lobby.id)
          .collection('users')
          .withConverter<LobbyUser>(
              fromFirestore: (snapshot, _) =>
                  LobbyUser.fromJson(snapshot.data()!),
              toFirestore: (lobbyUser, _) => lobbyUser.toJson());

  static CollectionReference<Message> _getMessagesCollectionRef(Lobby lobby) =>
      _lobbiesCollection
          .doc(lobby.id)
          .collection('messages')
          .withConverter<Message>(
              fromFirestore: (snapshot, _) =>
                  Message.fromJson(snapshot.data()!),
              toFirestore: (message, _) => message.toJson());

  static void startLobby(Lobby lobby) {
    final parameters = {
      "lobbyId": lobby.id,
    };
    _functions.httpsCallable("getPlacesRecommendations").call(parameters);
  }

  static Future<ActivitoUser> createUser(User currentUser) async {
    await _usersCollection.doc(currentUser.uid).set(
        ActivitoUser(currentUser.uid, currentUser.photoURL),
        SetOptions(merge: true));
    return (await _usersCollection.doc(currentUser.uid).get()).data()
        as ActivitoUser;
  }

  static void increaseInitialVoteCounter(Lobby lobby) {
    _lobbiesCollection
        .doc(lobby.id)
        .collection('individualFields')
        .doc("initialVotesCount")
        .update({'initialVotesCount': FieldValue.increment(1)});
  }

  static void addFinalVote(Lobby lobby, int voteIndex) {
    print('updating final votes');
    _lobbiesCollection
        .doc(lobby.id)
        .collection("individualFields")
        .doc('finalVotes')
        .set({voteIndex.toString(): FieldValue.increment(1)},
            SetOptions(merge: true));
  }

  static void exitLobby(LobbySession lobbySession) {
    final parameters = {
      "userId": lobbySession.thisLobbyUser!.id,
      "lobbyId": lobbySession.lobby!.id
    };
    _functions.httpsCallable("userExitLobby").call(parameters);
    LobbyScreen.messages = null;
    LobbyPlacesList.selectedTile = null;
    LobbyPlacesList.votedIndex = null;
  }

/*static void addFriend(String currentUserId, String friendId) {
    _usersCollection.doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([friendId])
    });
  }

  static void removeFriend(String currentUserId, String friendId) {
    _usersCollection.doc(currentUserId).update({
      'friends': FieldValue.arrayRemove([friendId])
    });
  }*/
}
