import 'package:activito/nice_widgets/AuthScreen.dart';
import 'package:activito/screens/AuthScreens/ProfileImagePickerScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/AuthService.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return AuthScreen(
        isLogin: false,
        emailAction: signUpWithEmail,
        facebookAction: signUpWithFacebook,
        googleAction: signUpWithGoogle);
  }

  Future<void> signUpWithGoogle(BuildContext context) async {
    if (!await AuthService.signInWithGoogle()) {
      Fluttertoast.showToast(msg: "Sign Up failed");
      return;
    }

    if (!AuthService.currentAdditionalUserInfo!.isNewUser) {
      userAlreadyExists();
      return;
    }

    continueToProfilePicPickerScreen();
  }

  Future<void> signUpWithFacebook() async {}

  Future<void> signUpWithEmail(String email, String password) async {
    bool loginResults =
        await AuthService.SignUpWithEmailAndPassword(email, password);
    if (!loginResults) {
      Fluttertoast.showToast(msg: "sign up failed");
      return;
    }

    continueToProfilePicPickerScreen();
  }

  continueToProfilePicPickerScreen() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProfileImagePickerScreen()));
    Navigator.pop(context);
  }

  Future<void> userAlreadyExists() async {
    Fluttertoast.showToast(msg: "user already exists");
    Navigator.pop(context, true);
  }
}
