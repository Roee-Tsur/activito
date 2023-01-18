import 'package:activito/nice_widgets/AuthScreen.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/AuthService.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return AuthScreen(
        isLogin: true,
        emailAction: loginWithEmail,
        facebookAction: loginWithFacebook,
        googleAction: loginWithGoogle);
  }

  void loginWithEmail(String email, String password) async {
    EasyLoading.show();
    bool loginResults = await AuthService.signInWithEmailAndPassword(email, password);
    if (!loginResults) {
      Fluttertoast.showToast(msg: "Login failed");
      return;
    }

    if (AuthService.currentAdditionalUserInfo!.isNewUser) {
      pickPhotoSkipSignUp();
      return;
    }

    loginSuccessful(loginResults);
  }

  void loginWithGoogle() async {
    EasyLoading.show();
    bool loginResults = await AuthService.signInWithGoogle();
    if (!loginResults) {
      Fluttertoast.showToast(msg: "Login failed");
      return;
    }

    if (AuthService.currentAdditionalUserInfo!.isNewUser) {
      pickPhotoSkipSignUp();
      return;
    }

    loginSuccessful(loginResults);
  }

  Future<void>
  loginWithFacebook() async {
    bool loginResults = await AuthService.signInWithFacebook();
    if (!loginResults) {
      Fluttertoast.showToast(msg: "Login failed");
      return;
    }

    loginSuccessful(loginResults);
  }

  // Navigator.pop returns true to initiate homepage to setState.
  void loginSuccessful(bool loginResults) async {
    EasyLoading.dismiss();
    Navigator.pop(context, loginResults);
  }

  void pickPhotoSkipSignUp() async {
    final results = Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProfileImagePickerScreen()));
    Navigator.pop(context, results);
  }
}
