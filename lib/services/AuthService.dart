import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/ActivitoUser.dart';
import 'Server.dart';

enum SignInMethods { GOOGLE, FACEBOOK, EMAIL }

class AuthService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static User? currentUser;
  static ActivitoUser? currentActivitoUser;
  static AdditionalUserInfo? currentAdditionalUserInfo;

  static Future<bool> SignUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      currentUser = userCredential.user;
      currentAdditionalUserInfo = userCredential.additionalUserInfo;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
      print('email signup in error: ${e.message}');
    }

    createOrUpdateFirestoreUser();
    return currentUser != null;
  }

  static Future<bool> signInWithGoogle() async {
    GoogleSignInAccount? userGoogleLoginAccount =
        await GoogleSignIn(scopes: ['email']).signIn();

    GoogleSignInAuthentication googleSignInAuth =
        await userGoogleLoginAccount!.authentication;

    AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleSignInAuth.idToken,
        accessToken: googleSignInAuth.accessToken);

    UserCredential userCredential =
        await firebaseAuth.signInWithCredential(authCredential);

    currentUser = userCredential.user;
    currentAdditionalUserInfo = userCredential.additionalUserInfo;

    createOrUpdateFirestoreUser();
    return currentUser != null;
  }

  static Future<bool> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      currentUser = userCredential.user;
      currentAdditionalUserInfo = userCredential.additionalUserInfo;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
      print('email sign in error: ${e.message}');
    }

    createOrUpdateFirestoreUser();
    return currentUser != null;
  }

  static Future<bool> signInWithFacebook() async {
    final loginResult = await FacebookAuth.instance.login();

    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

    currentUser = firebaseAuth.currentUser;

    createOrUpdateFirestoreUser();
    return currentUser != null;
  }

  static void initUser() {
    currentUser = firebaseAuth.currentUser;
    print("init user: ${currentUser.toString()}");

    firebaseAuth.userChanges().listen((event) {
      currentUser = event;
    });
  }

  static bool isUserConnected() => currentUser != null;

  static String getCurrentUserProfilePic() {
    if (isUserConnected() && currentUser!.photoURL != null)
      return currentUser!.photoURL!;
    else
      return '';
  }

  static void logout() {
    currentUser = null;
    firebaseAuth.signOut();
  }

  static Future<void> deleteProfilePic() async {
    await currentUser!.updatePhotoURL("");
    createOrUpdateFirestoreUser();
  }

  static setProfilePic(String photoURL) async {
    await currentUser!.updatePhotoURL(photoURL);
    createOrUpdateFirestoreUser();
  }

  static void resetPassword(String email) {
    firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<void> createOrUpdateFirestoreUser() async {
    if (currentUser != null)
      currentActivitoUser = await Server.createUser(currentUser!);
  }

/*static addFriend(String friendId) {
    Server.addFriend(currentUser!.uid, friendId);
  }

  static removeFriend(String friendId) {
    Server.removeFriend(currentUser!.uid, friendId);
  }*/
}
