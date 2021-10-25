import 'dart:io';

import 'package:activito/models/Lobby.dart';
import 'package:activito/models/ActivitoUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

import 'AuthService.dart';

class Server {
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseStorage _storage = FirebaseStorage.instance;
  static FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: "europe-west1");

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

  // calls functions with enteredCode and returns 0 (joined successfully) or 1 (error, didn't join) and a reason(String)
  static Future<Lobby?> joinLobby(String enteredCode, String userName) async {
    final functionParameters = {
      "enteredCode": enteredCode,
      "userName": userName
    };
    final resultsData =
        (await _functions.httpsCallable('joinLobby').call(functionParameters))
            .data;
    if (resultsData["requestStatus"] == 0) {
      Fluttertoast.showToast(msg: "joined lobby");
      final lobbyData =
          (await _lobbiesCollection.doc(resultsData["lobbyId"]).get()).data();
      return lobbyData as Lobby;
    } else
      Fluttertoast.showToast(
          msg: "didnt join lobby: ${resultsData["reason"]}",
          toastLength: Toast.LENGTH_LONG);
  }

  // creates lobby and then join it
  static Future<Lobby?> createLobby(String userName) async {
    final lobbyCode = (await _functions.httpsCallable('createLobby').call())
        .data["lobbyCode"] as String;
    return joinLobby(lobbyCode, userName);
  }

  static Future<ActivitoUser> createUser(String id, String email) async {
    final newUser = ActivitoUser(id, email);
    await _usersCollection.doc(id).set(newUser);
    return newUser;
  }

  static Future<ActivitoUser> getUser(String id) async =>
      ((await _usersCollection.doc(id).get()).data() as ActivitoUser);

  static Future setProfilePic(File croppedPic) async {
    String serverPicPath = "profilePics/${AuthService.getCurrentUserId()}.jpg";
    try {
      await _storage.ref().child(serverPicPath).putFile(croppedPic);
    } on Exception catch (e) {
      Fluttertoast.showToast(msg: "upload failed");
      print(e);
    }
  }

  static Future<Image> getCurrentUserProfilePic() async {
    String filePath = (await getApplicationDocumentsDirectory()).path + "profilePic.jpg";
    File profilePicFile = File(filePath);
    String serverPicPath = "profilePics/${AuthService.getCurrentUserId()}.jpg";
    await _storage.ref(serverPicPath).writeToFile(profilePicFile);

    return Image.file(profilePicFile);
  }

  static Future<Image> getUserProfilePic(String userID) async {
    //not sure if the directory is correct...
    String filePath = (await getTemporaryDirectory()).path + "profilePic-$userID.jpg";
    File profilePicFile = File(filePath);
    String serverPicPath = "profilePics/$userID.jpg";
    await _storage.ref(serverPicPath).writeToFile(profilePicFile);

    return Image.file(profilePicFile);
  }
}
